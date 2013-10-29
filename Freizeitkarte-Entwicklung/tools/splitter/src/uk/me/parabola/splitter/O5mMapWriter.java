/*
 * Copyright (C) 2012.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 or
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */ 
package uk.me.parabola.splitter;

import it.unimi.dsi.fastutil.longs.LongArrayList;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;

import uk.me.parabola.splitter.Relation.Member;

/**
 * Implements the needed methods to write the result in the o5m format. 
 * The routines to are based on the osmconvert.c source from Markus Weber who allows 
 * to copy them for any o5m IO, thanks a lot for that. 
 *
 * @author GerdP
 *
 */
public class O5mMapWriter extends AbstractOSMWriter{
	// O5M data set constants
	private static final int NODE_DATASET = 0x10;
	private static final int WAY_DATASET = 0x11;
	private static final int REL_DATASET = 0x12;
	private static final int BBOX_DATASET = 0xdb;
	//private static final int TIMESTAMP_DATASET = 0xdc;
	private static final int HEADER_DATASET = 0xe0;
	private static final int EOD_FLAG = 0xfe;
	private static final int RESET_FLAG = 0xff;

	private static final int STW__TAB_MAX = 15000;	// this is defined in the o5m format
	private static final int STW_HASH_TAB_MAX = 30011;  // (preferably a prime number)
	private static final int STW_TAB_STR_MAX = 250;// this is defined in the o5m format
	
	private static final String[] REL_REF_TYPES = {"0","1","2"};
	
	private static final double FACTOR = 10000000;

	private DataOutputStream dos;
	private Map<String, byte[]> wellKnownTagKeys;
	private Map<String, byte[]> wellKnownTagVals;

	private byte[][][] stw__tab; // string table
	private byte[] s1Bytes;
	private byte[] s2Bytes;
	// for delta calculations
	private long lastNodeId;
	private long lastWayId;
	private long lastRelId;
	private long lastRef[];
	private int lastLon,lastLat;
	
	boolean isFirstNode = true;
	boolean isFirstWay = true;
	boolean isFirstRel = true;
	
	// index of last entered element in string table
	short stw__tabi= 0; 
	
	  // has table; elements point to matching strings in stw__tab[];
	  // -1: no matching element;
	private short[] stw__hashtab;
	  // for to chaining of string table rows which match
	  // the same hash value; matching rows are chained in a loop;
	  // if there is only one row matching, it will point to itself;
	private short[] stw__tabprev;
	private short[] stw__tabnext;
	  // has value of this element as a link back to the hash table;
	  // a -1 element indicates that the string table entry is not used; 	
	private short[] stw__tabhash;
	
	private byte[] numberConversionBuf;
	
	//private long countCollisions;
	
	public O5mMapWriter(Area bounds, File outputDir, int mapId, int extra, Map<String, byte[]> wellKnownTagKeys, Map<String, byte[]> wellKnownTagVals) {
		super(bounds, outputDir, mapId, extra);
		this.wellKnownTagKeys = wellKnownTagKeys; 
		this.wellKnownTagVals= wellKnownTagVals; 
	}

	private void reset() throws IOException{
		dos.write(RESET_FLAG);
		resetVars();
	}
	
	/** reset the delta values and string table */
	private void resetVars(){
		
		lastNodeId = 0; lastWayId = 0; lastRelId = 0;
		lastRef[0] = 0; lastRef[1] = 0;lastRef[2] = 0;
		lastLon = 0; lastLat = 0;
		stw__tab = new byte[2][STW__TAB_MAX][];
		stw_reset();
	}
	
	public void initForWrite() {
		  // has table; elements point to matching strings in stw__tab[];
		  // -1: no matching element;
		stw__hashtab = new short[STW_HASH_TAB_MAX];
		  // for to chaining of string table rows which match
		  // the same hash value; matching rows are chained in a loop;
		  // if there is only one row matching, it will point to itself;
		stw__tabprev = new short[STW__TAB_MAX];
		stw__tabnext = new short[STW__TAB_MAX];
		  // has value of this element as a link back to the hash table;
		  // a -1 element indicates that the string table entry is not used; 	
		stw__tabhash = new short[STW__TAB_MAX];
		lastRef = new long[3];
		numberConversionBuf = new byte[60];
		resetVars();

		String filename = String.format(Locale.ROOT, "%08d.o5m", mapId);
		try {
			FileOutputStream fos = new FileOutputStream(new File(outputDir, filename));
			dos = new DataOutputStream(new BufferedOutputStream(fos));
			dos.write(RESET_FLAG);
			writeHeader();
			writeBBox();
		} catch (IOException e) {
			System.out.println("Could not open or write file header. Reason: " + e.getMessage());
			throw new RuntimeException(e);
		}
	}

	private void writeHeader() throws IOException {
		ByteArrayOutputStream stream = new ByteArrayOutputStream();
		byte[] id = {'o','5','m','2'};
		stream.write(id);
		writeDataset(HEADER_DATASET,stream);
	}

	
	private void writeBBox() throws IOException {
		ByteArrayOutputStream stream = new ByteArrayOutputStream();
		writeSignedNum((long)(Utils.toDegrees(bounds.getMinLong()) * FACTOR), stream);
		writeSignedNum((long)(Utils.toDegrees(bounds.getMinLat()) * FACTOR), stream);
		writeSignedNum((long)(Utils.toDegrees(bounds.getMaxLong()) * FACTOR), stream);
		writeSignedNum((long)(Utils.toDegrees(bounds.getMaxLat()) * FACTOR), stream);
		writeDataset(BBOX_DATASET,stream);
	}

	private void writeDataset(int fileType, ByteArrayOutputStream stream) throws IOException {
		dos.write(fileType);
		writeUnsignedNum(stream.size(), dos);
		stream.writeTo(dos);
	}

	public void finishWrite() {
		try {
			dos.write(EOD_FLAG);
			dos.close();
			stw__hashtab = null;
			stw__tabprev = null;
			stw__tabnext = null;
			stw__tabhash = null;
			lastRef = null;
			numberConversionBuf = null;
			stw__tab = null;
			//System.out.println(mapId + " collisions=" + Utils.format(countCollisions));
		} catch (IOException e) {
			System.out.println("Could not write end of file: " + e);
		}
	}

	@Override
	public void write(Node node) throws IOException {
		if (isFirstNode){
			isFirstNode = false;
			reset();
		}
		ByteArrayOutputStream stream = new ByteArrayOutputStream();
		long delta = node.getId() - lastNodeId; lastNodeId = node.getId(); 
		writeSignedNum(delta, stream);
		stream.write(0x00); // no version info
		int o5Lon = (int)(node.getLon() * FACTOR);
		int o5Lat = (int)(node.getLat() * FACTOR);
		int deltaLon = o5Lon - lastLon; lastLon = o5Lon;
		int deltaLat = o5Lat - lastLat; lastLat = o5Lat;
		writeSignedNum(deltaLon, stream);
		writeSignedNum(deltaLat, stream);
		writeTags(node, stream);
		writeDataset(NODE_DATASET,stream);
	}

	public void write(Way way) throws IOException {
		if (isFirstWay){
			isFirstWay = false;
			reset();
		}
		ByteArrayOutputStream stream = new ByteArrayOutputStream();
		long delta = way.getId() - lastWayId; lastWayId = way.getId();
		writeSignedNum(delta, stream);
		stream.write(0x00); // no version info
		ByteArrayOutputStream refStream = new ByteArrayOutputStream();
		LongArrayList refs = way.getRefs();
		int numRefs = refs.size();
		for (int i = 0; i < numRefs; i++){
			long ref = refs.getLong(i);
			delta = ref - lastRef[0]; lastRef[0] = ref;
			writeSignedNum(delta, refStream);
		}
		writeUnsignedNum(refStream.size(),stream);
		refStream.writeTo(stream);
		writeTags(way, stream);
		writeDataset(WAY_DATASET,stream);
	}

	public void write(Relation rel) throws IOException {
		if (isFirstRel){
			isFirstRel = false;
			reset();
		}
		ByteArrayOutputStream stream = new ByteArrayOutputStream(256);
		long delta = rel.getId() - lastRelId; lastRelId = rel.getId();
		writeSignedNum(delta, stream);
		stream.write(0x00); // no version info
		ByteArrayOutputStream memStream = new ByteArrayOutputStream(256);
		for (Member mem: rel.getMembers()){
			writeRelRef(mem, memStream);
		}
		writeUnsignedNum(memStream.size(),stream);
		memStream.writeTo(stream);
		writeTags(rel, stream);
		writeDataset(REL_DATASET,stream);
	}

	private void writeRelRef(Member mem, ByteArrayOutputStream memStream) throws IOException {
		int refType = 0;
		String type = mem.getType(); 
		if ("node".equals(type)) 
			refType = 0;
		else if ("way".equals(type)) 
			refType = 1;
		else if ("relation".equals(type)) 
			refType = 2;
		else {
			assert (false); // Software bug: Unknown entity.
		}
		long delta = mem.getRef() - lastRef[refType]; lastRef[refType] = mem.getRef(); 
		writeSignedNum(delta, memStream);
		stw_write(REL_REF_TYPES[refType] + mem.getRole(), null, memStream); 
	}

	private void writeTags(Element element, OutputStream stream) throws IOException {
		if (!element.hasTags())
			return;
		Iterator<Element.Tag> it = element.tagsIterator();
		while (it.hasNext()) {
			Element.Tag entry = it.next();
			stw_write(entry.key, entry.value, stream);
		}
	}

	
	private void stw_write(String s1, String s2, OutputStream stream) throws IOException {
		int hash;
		int ref;
		s1Bytes = wellKnownTagKeys.get(s1);
		if (s1Bytes == null){
			s1Bytes = s1.getBytes("UTF-8");
		}
		if (s2 != null){
			s2Bytes = wellKnownTagVals.get(s2);
			if (s2Bytes == null){ 
				s2Bytes= s2.getBytes("UTF-8");
			}
		}
		else 
			s2Bytes = null;

		//  try to find a matching string (pair) in string table
		{
			int i;  // index in stw__tab[] 
			ref = -1;  // ref invalid (default)
			
			hash = stw_hash(s1,s2);
		    if (hash >= 0){
		    	i = stw__hashtab[hash]; 
		    	if(i >= 0)  // string (pair) presumably stored already
		        	ref = stw__getref(i);
		    }  // end   string (pair) short enough for the string table
		    if(ref >= 0) {  // we found the string (pair) in the table
		    	writeUnsignedNum(ref, stream);  // write just the reference
		    	return;
		    }  // end   we found the string (pair) in the table
		    else {  // we did not find the string (pair) in the table
		    	// write string data
				stream.write(0x00); 
				stream.write(s1Bytes);
				stream.write(0x00); 
				if (s2Bytes != null){
					stream.write(s2Bytes);
					stream.write(0x00); 
				}
		    	
				if(hash < 0){  // string (pair) too long,
					// cannot be stored in string table
					return;
				}
		    }  // end   we did not find the string (pair) in the table
		}  // end   try to find a matching string (pair) in string table
		// here: there is no matching string (pair) in the table

		// free new element - if still being used 
		{
			int h0;  // hash value of old element

			h0 = stw__tabhash[stw__tabi];
			if(h0 >= 0) {  // new element in string table is still being used
				// delete old element
				if(stw__tabnext[stw__tabi] == stw__tabi)
					// self-chain, i.e., only this element
					stw__hashtab[h0]= -1;  // invalidate link in hash table
				else {  // one or more other elements in chain
					stw__hashtab[h0] = stw__tabnext[stw__tabi];  // just to ensure
					// that hash entry does not point to deleted element
					// now unchain deleted element
					stw__tabprev[stw__tabnext[stw__tabi]]= stw__tabprev[stw__tabi];
					stw__tabnext[stw__tabprev[stw__tabi]]= stw__tabnext[stw__tabi];
				}  // end   one or more other elements in chain
			}  // end   next element in string table is still being used
		}  // end   free new element - if still being used

		// enter new string table element data  
		{
			int i;
			
			stw__tab[0][stw__tabi] = s1Bytes;
			stw__tab[1][stw__tabi] = s2Bytes;
			
			i = stw__hashtab[hash];
			if(i < 0)  // no reference in hash table until now
				stw__tabprev[stw__tabi] = stw__tabnext[stw__tabi] = stw__tabi;
			// self-link the new element;
			else {  // there is already a reference in hash table
				// in-chain the new element
				stw__tabnext[stw__tabi] = (short) i;
				stw__tabprev[stw__tabi] = stw__tabprev[i];
				stw__tabnext[stw__tabprev[stw__tabi]] = stw__tabi;
				stw__tabprev[i] = stw__tabi;
				//countCollisions++;
			}
			stw__hashtab[hash] = stw__tabi; // link the new element to hash table
			stw__tabhash[stw__tabi] = (short) hash; // backlink to hash table element
			// new element now in use; set index to oldest element
			if (++stw__tabi >= STW__TAB_MAX) { // index overflow
				stw__tabi= 0;  // restart index
			}  // end   index overflow
		}  // end   enter new string table element data
	}

	int stw__getref(final int stri) {
		int strie;  // index of last occurrence 
		int ref; 

		strie= stri;
		int pos = stri;
		do{
			// compare the string (pair) with the tab entry 
			byte[] tb1 = stw__tab[0][pos];
			if (Arrays.equals(tb1, s1Bytes)){
				// first string equal to first string in table
				byte[] tb2 = stw__tab[1][pos];
				if (Arrays.equals(tb2, s2Bytes)){
					// second string equal to second string in table
					ref = stw__tabi - pos;
					if (ref <= 0)
						ref += STW__TAB_MAX;
					return ref;
				}
			}
			pos = stw__tabnext[pos]; 
		} while(pos!=strie); 
		return -1;
	}
	
	void stw_reset() {
		// clear string table and string hash table;
		// must be called before any other procedure of this module
		// and may be called every time the string processing shall
		// be restarted;

		stw__tabi = 0;
		Arrays.fill(stw__tabhash, (short)-1);
		Arrays.fill(stw__hashtab, (short)-1);
	}  
		 	
	/**
	 * get hash value of a string pair
	 * @param s2 
	 * @param s1 
	 * @return  hash value in the range 0..(STW__TAB_MAX-1) 
	 * or -1 if the strings are longer than STW_TAB_STR_MAX bytes in total
	 * @throws IOException 
	 */
	private int stw_hash(String s1, String s2) throws IOException{
		int len = s1Bytes.length;
		if (s2Bytes != null)
			len += s2Bytes.length;
		if (len > STW_TAB_STR_MAX)
			return -1;
		int hash = s1.hashCode();
		if (s2 != null)
			hash ^= s2.hashCode();
		
		return Math.abs(hash % STW__TAB_MAX);
	}
	
	private int writeUnsignedNum(int number, OutputStream stream)throws IOException {
		int num = number;
		int cntBytes = 0;
		int part = num & 0x7f;
		if (part == num){ // just one byte
			stream.write(part);
			return 1;
		}
		do{
			numberConversionBuf[cntBytes++] = (byte)(part | 0x80);
			num >>= 7;
			part = num & 0x7f;
		} while(part != num);
		numberConversionBuf[cntBytes++] = (byte)(part);
		stream.write(numberConversionBuf,0,cntBytes);
		return cntBytes;
	}
	
	private int writeSignedNum(long num, OutputStream stream)throws IOException {
		int cntBytes = 0;
		  // write a long as signed varying integer.
		  // return: bytes written;
		long u;
		int part;

		if (num < 0){
			u = -num;
			u= (u<<1)-1;
		}
		else{
		    u= num<<1;
		}
		part = (int)(u & 0x7f);
		if(part == u) {  // just one byte
			stream.write(part);
			return 1;
		}
		do {
			numberConversionBuf[cntBytes++] = (byte)(part | 0x80);
		    u >>= 7;
		    part = (int)(u & 0x7f);
		} while(part !=u);
		numberConversionBuf[cntBytes++] = (byte)(part);
		stream.write(numberConversionBuf,0,cntBytes);
		return cntBytes;
	}
}
