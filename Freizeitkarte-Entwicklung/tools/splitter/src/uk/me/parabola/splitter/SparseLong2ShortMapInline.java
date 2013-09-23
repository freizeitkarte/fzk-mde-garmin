package uk.me.parabola.splitter;

import it.unimi.dsi.fastutil.ints.Int2ObjectOpenHashMap;
import it.unimi.dsi.fastutil.ints.IntArrayList;
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap;

import java.util.Arrays;



/**
 * SparseLong2ShortMapInline implements SparseLong2ShortMapFunction 
 * optimized for low memory requirements and inserts in sequential order.
 * Don't use this for a rather small number of pairs. 
 *
 * Inspired by SparseInt2ShortMapInline.
 * 
 * A HashMap is used to address large vectors which address chunks. The HashMap 
 * is the only part that stores long values, and it will be very small as long 
 * as long as input is normal OSM data and not something with random numbers. 
 * A chunk stores up to CHUNK_SIZE values. A separately stored bit-mask is used
 * to separate used and unused entries in the chunk. Thus, the chunk length 
 * depends on the number of used entries, not on the highest used entry.
 * A typical (uncompressed) chunk looks like this:
 * v1,v1,v1,v1,v1,v1,v2,v2,v2,v2,v1,v1,v1,v1,v1,u,?,?,...}
 * v1,v2: values stored in the chunk
 * u: "unassigned" value
 * ?: anything
 * 
 * After applying Run Length Encryption on this the chunk looks like this:
 * {u,6,v1,4,v2,5,v1,?,?,?}
 * The unassigned value on index 0 signals a compressed chunk.
 * 
 * An (uncompressed) ONE_VALUE_CHUNK may look like this:
 * {v1,v1,v1,v1,v1,v1,v1,v1,v1,v1,v1,u,?,?,...}
 * This is stored without run length info in the shortest possible trunk:
 * {v1}
 * 
 * Fortunately, OSM data is distributed in a way that most(!) chunks contain
 * just one distinct value, so most chunks can be stored in 24 or 32 bytes
 * instead of 152 bytes for the worst case (counting also the padding bytes).

 * Since we have keys with 64 bits, we have to divide the key into 3 parts:
 * 37 bits for the value that is stored in the HashMap.
 * 21 bits for the chunkId (this gives the required length of a large vector)       
 * 6 bits for the position in the chunk
 * 
 * The chunkId identifies the position of a 32bit integer value (stored in the large vector).
 * A chunk is stored in a chunkStore which is a 3-dimensional array.
 * We group chunks of equally length together in stores of 64 entries. 
 * To find the right position of a new chunk, we need three values: x,y, and z.
 * x is the length of the chunk (the number of required shorts) (1-64, we store the value decremented by 1 to have 0-63)
 * y is the position of the store (0-524287)
 * z is the position of the chunk within the store. (0-63)
 * The maximum values for these three values are chosen so that we can place them 
 * together into one int (32 bits). 
 */

public class SparseLong2ShortMapInline implements SparseLong2ShortMapFunction{
	private static final long TOP_ID_MASK = 0xfffffffff8000000L;  			// the part of the key that is saved in the HashMap 
	private static final int TOP_ID_SHIFT = Long.numberOfTrailingZeros(TOP_ID_MASK);	

	private static final int CHUNK_STORE_ELEMS = 64; 			  
	private static final int CHUNK_STORE_BITS_FOR_Z = 6; 		  
	private static final int CHUNK_STORE_BITS_FOR_Y = 19; 		  
	private static final int CHUNK_STORE_BITS_FOR_X = 6; 		  
	private static final int CHUNK_STORE_X_MASK = 0x3f;
	private static final int CHUNK_STORE_Y_MASK = 0x7ffff;
	private static final int CHUNK_STORE_Z_MASK = 0x3f;
	private static final int CHUNK_STORE_USED_FLAG_MASK = 1<<31;
	private static final int CHUNK_STORE_Y_SHIFT = CHUNK_STORE_BITS_FOR_X;
	private static final int CHUNK_STORE_Z_SHIFT = CHUNK_STORE_BITS_FOR_X + CHUNK_STORE_BITS_FOR_Y;
	
	private static final int CHUNK_SIZE = 64; 							// 64  = 1<< 6 (last 6 bits of the key) 
	private static final long CHUNK_OFFSET_MASK = CHUNK_SIZE-1;  		// the part of the key that contains the offset in the chunk
	private static final long OLD_CHUNK_ID_MASK = ~CHUNK_OFFSET_MASK;	// first 58 bits of a long. If this part of the key changes, a different chunk is needed
	private static final long CHUNK_ID_MASK     = ~TOP_ID_MASK; 		// the bits that are not stored in the HashMap
	
	private static final long INVALID_CHUNK_ID = 1L; // must NOT be divisible by CHUNK_SIZE 
	private static final int LARGE_VECTOR_SIZE = (int)(CHUNK_ID_MASK/ CHUNK_SIZE + 1); // number of entries addressed by one topMap entry 

	private static final int ONE_VALUE_CHUNK_SIZE = 1; 

	/** What to return on unassigned indices */
	private short unassigned = UNASSIGNED;
	private long size;

	
	private long currentChunkId = INVALID_CHUNK_ID; 
	private short [] currentChunk = new short[CHUNK_SIZE];  // stores the values in the real position 
	private short [] tmpWork = new short[CHUNK_SIZE];  // a chunk after applying the "mask encoding"
	private short [] RLEWork = new short[CHUNK_SIZE];  // for the RLE-compressed chunk


	// for statistics
	private long [] countChunkLen; 
	private long expanded = 0;
	private long uncompressedLen = 0;
	private long compressedLen = 0;
	private int storedLengthOfCurrentChunk = 0;
	private int currentChunkIdInStore = 0;

	private Long2ObjectOpenHashMap<int[]> topMap; 
	private short[][][] chunkStore; 
	private long[][][] maskStore; 
	private int[] freePosInSore;
	// maps chunks that can be reused  
	private Int2ObjectOpenHashMap<IntArrayList> reusableChunks;
	
	/**
	 * A map that stores pairs of (OSM) IDs and short values identifying the
	 * areas in which the object (node,way) with the ID occurs.
	 */
	SparseLong2ShortMapInline() {
		clear();
	}

	/**
	 * Count how many of the lowest X bits in mask are set
	 * 
	 * @return
	 */
	private int countUnder(long mask, int lowest) {
		return Long.bitCount(mask & ((1L << lowest) - 1));
	}

	/**
	 * Try to use Run Length Encoding to compress the chunk stored in tmpWork. In most
	 * cases this works very well because chunks often have only one 
	 * or two distinct values.
	 * @param maxlen: number of elements in the chunk. 
	 * @return -1 if compression doesn't save space, else the number of elements in the 
	 * compressed chunk stored in buffer RLEWork.
	 */
	private int chunkCompressRLE (int maxlen){
		int opos =  1;
		for (int i = 0; i < maxlen; i++) {
			short runLength = 1;
			while (i+1 < maxlen && tmpWork[i] == tmpWork[i+1]) {
				runLength++;
				i++;
			}
			if (opos+2 >= tmpWork.length) 
				return -1; // compressed record is not shorter
			RLEWork[opos++] = runLength;
			RLEWork[opos++] = tmpWork[i]; 
		}
		if (opos == 3){
			// special case: the chunk contains only one distinct value
			// we can store this in a length-1 chunk because we don't need
			// the length counter nor the compression flag
			RLEWork[0] = RLEWork[2];
			return ONE_VALUE_CHUNK_SIZE;
		}

		if (opos < maxlen){
			RLEWork[0] = unassigned; // signal a normal compressed record
			return opos;
		}
		else 
			return -1;
	}
	
	/**
	 * Try to compress the data in currentChunk and store the result in the chunkStore.
	 */
	private void saveCurrentChunk(){
		long mask = 0;
		int RLELen = -1;
		int opos = 0;
		long elementMask = 1L;
		short [] chunkToSave;
		// move used entries to the beginning
		for (int j=0; j < CHUNK_SIZE; j++){
			if (currentChunk[j] != unassigned) {
				mask |= elementMask;
				tmpWork[opos++] = currentChunk[j];
			}
			elementMask <<= 1;
		}
		uncompressedLen += opos;
		if (opos > ONE_VALUE_CHUNK_SIZE)
			RLELen =  chunkCompressRLE(opos);
		if (RLELen > 0){
			chunkToSave = RLEWork;
			opos = RLELen;
		}
		else
			chunkToSave = tmpWork;
		compressedLen += opos;
		putChunk(currentChunkId, chunkToSave, opos, mask);
	}

	@Override
	public boolean containsKey(long key) {
		return get(key) != unassigned;
	}


	@Override
	public short put(long key, short val) {
		long chunkId = key & OLD_CHUNK_ID_MASK;
		if (val == unassigned) {
			throw new IllegalArgumentException("Cannot store the value that is reserved as being unassigned. val=" + val);
		}
		int chunkoffset = (int) (key & CHUNK_OFFSET_MASK);
		short out;
		if (currentChunkId == chunkId){
			out = currentChunk[chunkoffset];
			currentChunk[chunkoffset] = val;
			if (out == unassigned)
				size++;
			return out;
		}

		if (currentChunkId != INVALID_CHUNK_ID){
			// we need a different chunk
			saveCurrentChunk();
		}

		fillCurrentChunk(key);
		out = currentChunk[chunkoffset];
		currentChunkId = chunkId;
		currentChunk[chunkoffset] = val;
		if (out == unassigned)
			size++;
		
		return out;
	}


	/**
	 * Check if we already have a chunk for the given key. If no,
	 * fill currentChunk with default value, else with the saved
	 * chunk. 
	 * @param key
	 */
	private void fillCurrentChunk(long key) {
		Arrays.fill(currentChunk, unassigned);
		storedLengthOfCurrentChunk = 0;
		currentChunkIdInStore = 0;
		long topID = key >> TOP_ID_SHIFT;
		int[] largeVector = topMap.get(topID);
		if (largeVector == null)
			return;
		int chunkid = (int) (key & CHUNK_ID_MASK) / CHUNK_SIZE;
		
		int idx = largeVector[chunkid];
		if (idx == 0)
			return;
		currentChunkIdInStore = idx;
		int x = idx & CHUNK_STORE_X_MASK;
		int y = (idx >> CHUNK_STORE_Y_SHIFT) & CHUNK_STORE_Y_MASK;
		int chunkLen = x +  1;
		short [] store = chunkStore[x][y];
		int z = (idx >> CHUNK_STORE_Z_SHIFT) & CHUNK_STORE_Z_MASK;

		long chunkMask = maskStore[x][y][z];
		long elementmask = 0;

		++expanded;
		storedLengthOfCurrentChunk = x;
		int startPos = z * chunkLen + 1;
		boolean isCompressed = (chunkLen == ONE_VALUE_CHUNK_SIZE || store[startPos] == unassigned); 
		if (isCompressed){
			int opos = 0;
			if (chunkLen == ONE_VALUE_CHUNK_SIZE) {
				// decode one-value-chunk
				short val = store[startPos];
				elementmask = 1;
				for (opos = 0; opos<CHUNK_SIZE; opos++){
					if ((chunkMask & elementmask) != 0)
						currentChunk[opos] = val;
					elementmask <<= 1;
				}
			}
			else {
				// decode RLE-compressed chunk with multiple values
				int ipos = startPos + 1;
				int len = store[ipos++];
				short val = store[ipos++];
				while (len > 0){
					while (len > 0 && opos < currentChunk.length){
						if ((chunkMask & 1L << opos) != 0){ 
							currentChunk[opos] = val; 
							--len;
						}
						++opos;
					}
					if (ipos+1 < startPos + chunkLen){
						len = store[ipos++];
						val = store[ipos++];
					}
					else len = -1;
				}
			}
		}
		else {
			// decode uncompressed chunk
			int ipos = startPos;
			elementmask = 1;
			for (int opos=0; opos < CHUNK_SIZE; opos++) {
				if ((chunkMask & elementmask) != 0) 
					currentChunk[opos] = store[ipos++];
				elementmask <<= 1;
			}
		}
	}

	@Override
	public short get(long key){
		long chunkId = key & OLD_CHUNK_ID_MASK;
		int chunkoffset = (int) (key & CHUNK_OFFSET_MASK);

		if (currentChunkId == chunkId)
			 return currentChunk[chunkoffset];
		
		long topID = key >> TOP_ID_SHIFT;
		int[] largeVector = topMap.get(topID);
		if (largeVector == null)
			return unassigned;
		int chunkid = (int) (key & CHUNK_ID_MASK) / CHUNK_SIZE;
		
		int idx = largeVector[chunkid];
		if (idx == 0)
			return unassigned;
		int x = idx & CHUNK_STORE_X_MASK;
		int y = (idx >> CHUNK_STORE_Y_SHIFT) & CHUNK_STORE_Y_MASK;
		int chunkLen = x +  1;
		short [] store = chunkStore[x][y];
		int z = (idx >> CHUNK_STORE_Z_SHIFT) & CHUNK_STORE_Z_MASK;
		
		long chunkMask = maskStore[x][y][z];

		long elementmask = 1L << chunkoffset;
		if ((chunkMask & elementmask) == 0) 
			return unassigned; // not in chunk 
		else {
			int startOfChunk = z * chunkLen + 1;
			// the map contains the key, extract the value
			short firstAfterMask = store[startOfChunk];
			if (chunkLen == ONE_VALUE_CHUNK_SIZE)
				return firstAfterMask;
			else {
				int index = countUnder(chunkMask, chunkoffset);
				if (firstAfterMask == unassigned){
					// extract from compressed chunk 
					short len; 
					for (int j=1; j < chunkLen; j+=2){
						len =  store[j+startOfChunk];
						index -= len;
						if (index < 0) return store[j+startOfChunk+1];
					}
					return unassigned; // should not happen
				}
				else {
					// extract from uncompressed chunk
					return store[index +  startOfChunk];
				}
			}
		}
	}

	@Override
	public void clear() {
		System.out.println(this.getClass().getSimpleName() + ": Allocating three-tier structure to save area info (HashMap->vector->chunkvector)");
		topMap = new Long2ObjectOpenHashMap<int[]>();
		chunkStore = new short[CHUNK_SIZE+1][][];
		maskStore = new long[CHUNK_SIZE+1][][];
		freePosInSore = new int[CHUNK_SIZE+1];
		countChunkLen = new long[CHUNK_SIZE +  1 ]; // used for statistics
		reusableChunks = new Int2ObjectOpenHashMap<IntArrayList>();
		size = 0;
		uncompressedLen = 0;
		compressedLen = 0;
		expanded = 0;
		//test();
	}

	@Override
	public long size() {
		return size;
	}

	@Override
	public short defaultReturnValue() {
		return unassigned;
	}

	@Override
	public void defaultReturnValue(short arg0) {
		unassigned = arg0;
	}

	/**
	 * Find the place were a chunk has to be stored and copy the content
	 * to this place. 
	 * @param key the (OSM) id
	 * @param chunk  the chunk 
	 * @param len the number of used bytes in the chunk
	 */
	private void putChunk (long key, short[] chunk, int len, long mask) {
		long topID = key >> TOP_ID_SHIFT;
		int[] largeVector = topMap.get(topID);
		if (largeVector == null){
			largeVector = new int[LARGE_VECTOR_SIZE];
			topMap.put(topID, largeVector);
		}
		
		int chunkid = (int) (key & CHUNK_ID_MASK) / CHUNK_SIZE;
		int x = len - 1;
		if (storedLengthOfCurrentChunk > 0){
			// this is a rewrite, add the previously used chunk to the reusable list 
			IntArrayList reusableChunk = reusableChunks.get(storedLengthOfCurrentChunk);
			if (reusableChunk == null){
				reusableChunk = new IntArrayList(8);
				reusableChunks.put(storedLengthOfCurrentChunk, reusableChunk);
			}
			reusableChunk.add(currentChunkIdInStore);
		}
		if (chunkStore[x] == null){
			chunkStore[x] = new short[2][];
			maskStore[x] = new long[2][];
		}
		IntArrayList reusableChunk = reusableChunks.get(x); 
		Integer reusedIdx = null; 
		int y,z;
		short []store;
		if (reusableChunk != null && reusableChunk.isEmpty() == false){
			reusedIdx = reusableChunk.remove(reusableChunk.size()-1);
		}
		if (reusedIdx != null){
			y = (reusedIdx >> CHUNK_STORE_Y_SHIFT) & CHUNK_STORE_Y_MASK;
			z = (reusedIdx >> CHUNK_STORE_Z_SHIFT) & CHUNK_STORE_Z_MASK;
			store = chunkStore[x][y];
		} else {
			y = ++freePosInSore[x] / CHUNK_STORE_ELEMS;
			if (y >= chunkStore[x].length){
				// resize
				int newElems = Math.min(y*2,1<<CHUNK_STORE_BITS_FOR_Y);
				short[][] tmp = new short[newElems][]; 
				System.arraycopy(chunkStore[x], 0, tmp, 0, y);
				chunkStore[x] = tmp;
				long[][] tmpMask = new long[newElems][]; 
				System.arraycopy(maskStore[x], 0, tmpMask, 0, y);
				maskStore[x] = tmpMask;
			}
			if (chunkStore[x][y] == null){
				chunkStore[x][y] = new short[len * (CHUNK_STORE_ELEMS)+2];
				maskStore[x][y] = new long[CHUNK_STORE_ELEMS];
			}
			store = chunkStore[x][y];
			z = store[0]++;
			++countChunkLen[len];
		}
		maskStore[x][y][z] = mask;

		if (len > 1)
			System.arraycopy(chunk, 0, store, z*len+1, len);
		else 
			store[z*len+1] = chunk[0];
		assert x < 1<<CHUNK_STORE_BITS_FOR_X;
		assert y < 1<<CHUNK_STORE_BITS_FOR_Y;
		assert z < 1<<CHUNK_STORE_BITS_FOR_Z;
		int idx = CHUNK_STORE_USED_FLAG_MASK 
				| (z & CHUNK_STORE_Z_MASK)<<CHUNK_STORE_Z_SHIFT 
				| (y & CHUNK_STORE_Y_MASK)<< CHUNK_STORE_Y_SHIFT 
				| (x & CHUNK_STORE_X_MASK);
					
		assert idx  != 0;
		largeVector[chunkid] = idx;
	}

	@Override
	/**
	 * calculate and print performance values regarding memory 
	 */
	public void stats(int msgLevel) {
		long totalOverhead = 0;
		long totalBytes = 0;
		long totalChunks = 0;
		int i;
		
		if (size() == 0){
			System.out.println("Map is empty");
			return;
		}
		for (i=1; i <=CHUNK_SIZE; i++) {
			long bytes = countChunkLen[i] * (i*2+8) ; // 2 bytes for the shorts + 8 bytes for the mask
			totalChunks += countChunkLen[i];
			int freePos = freePosInSore[i-1];
			long overhead = (freePos == 0) ? 0: (64 - freePos % 64) * i * 2 + 
					chunkStore[i-1].length * 4 + maskStore[i-1].length * 8;
			if (msgLevel > 0) { 
				System.out.println("Length-" + i + " chunks: " + Utils.format(countChunkLen[i]) + ", used Bytes including overhead: " + Utils.format(bytes+overhead));
				//System.out.println("Length-" + i + " stores: " + Utils.format(chunkStore[i-1].length) + " pos " + freePosInSore[i-1]);
			}
			totalBytes += bytes;
			totalOverhead += overhead;
		}
		totalOverhead += topMap.size() * (long)LARGE_VECTOR_SIZE * 4;
		
		float bytesPerKey = (size()==0) ? 0: (float)((totalBytes + totalOverhead)*100 / size()) / 100;
		if (msgLevel > 0){
			System.out.println();
			System.out.println("Number of stored ids: " + Utils.format(size()) + " require ca. " + 
					bytesPerKey + " bytes per pair. " + 
					totalChunks + " chunks are used, the avg. number of values in one "+CHUNK_SIZE+"-chunk is " + 
					((totalChunks==0) ? 0 :(size() / totalChunks)) + "."); 
		}
		System.out.println("Map details: bytes/overhead " + Utils.format(totalBytes) + " / " + Utils.format(totalOverhead) + ", overhead includes " + 
				topMap.size() + " arrays with " + LARGE_VECTOR_SIZE * 4/1024/1024 + " MB");  
		if (msgLevel > 0 & uncompressedLen > 0){
			System.out.print("RLE compresion info: compressed / uncompressed size / ratio: " + 
					Utils.format(compressedLen) + " / "+ 
					Utils.format(uncompressedLen) + " / "+
					Utils.format(Math.round(100-(float) (compressedLen*100/uncompressedLen))) + "%");
			if (expanded > 0 )
				System.out.print(", times fully expanded: " + Utils.format(expanded));
			System.out.println();
		}
		
	}
	/*
	void  test(){
		for (int z = 0; z < 64; z++){
			for (int y = 0; y < 10; y++){
				for (int x=0; x < 64; x++){
					int idx = CHUNK_STORE_USED_FLAG_MASK 
							| (z & CHUNK_STORE_Z_MASK)<<CHUNK_STORE_Z_SHIFT 
							| (y & CHUNK_STORE_Y_MASK)<< CHUNK_STORE_Y_SHIFT 
							| (x & CHUNK_STORE_X_MASK);
					// extract 
					int x2 = idx & CHUNK_STORE_X_MASK;
					int y2 = (idx >> CHUNK_STORE_Y_SHIFT) & CHUNK_STORE_Y_MASK;
					int z2 = (idx >> CHUNK_STORE_Z_SHIFT) & CHUNK_STORE_Z_MASK;
					assert x == x2;
					assert y == y2;
					assert z == z2;
				}
			}
		}
	}
	*/
}



 