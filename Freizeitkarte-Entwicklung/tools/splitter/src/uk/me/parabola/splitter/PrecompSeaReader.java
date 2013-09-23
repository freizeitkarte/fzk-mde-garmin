/*
 * Copyright (C) 2010-2012.
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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.Reader;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.zip.GZIPInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.xmlpull.v1.XmlPullParserException;
import crosby.binary.file.BlockInputStream;

/**
 * Reader for precompiled sea data.
 * This is mostly a copy of the corresponding code in mkgmap SeaGenerator. 
 * @author GerdP 
 *
 */
public class PrecompSeaReader {

	/** The size (lat and long) of the precompiled sea tiles */
	private final static int PRECOMP_RASTER = 1 << 15;

	private static final byte SEA_TILE = 's';
	private static final byte LAND_TILE = 'l';
	private static final byte MIXED_TILE = 'm';


	// useful constants defining the min/max map units of the precompiled sea tiles
	private static final int MIN_LAT = Utils.toMapUnit(-90.0);
	private static final int MAX_LAT = Utils.toMapUnit(90.0);
	private static final int MIN_LON = Utils.toMapUnit(-180.0);
	private static final int MAX_LON = Utils.toMapUnit(180.0);
	private final static Pattern keySplitter = Pattern.compile(Pattern.quote("_"));

	private final Area bounds;
	private final File precompSeaDir;
	private byte[][] precompIndex;
	private String precompSeaExt;
	private String precompSeaPrefix;
	private String precompZipFileInternalPath;
	private ZipFile zipFile;

	public PrecompSeaReader(Area bounds, File precompSeaDir) {
		this.bounds = bounds;
		this.precompSeaDir = precompSeaDir;
		init();
	}

	/**
	 * Process all precompiled sea tiles.
	 * @param processor The processor that is called 
	 * @throws XmlPullParserException
	 */
	public void processMap(DensityMapCollector processor) throws XmlPullParserException {
		for (String tileName: getPrecompKeyNames()){
			InputStream is = getStream(tileName);
			if (is != null){
				try{
					if (tileName.endsWith(".pbf")){
						BinaryMapParser binParser = new BinaryMapParser(processor, null);
						BlockInputStream blockinput = (new BlockInputStream(is, binParser));
						try {
							blockinput.process();
						} finally {
							blockinput.close();
						}
					} else {
						// No, try XML.
						OSMParser parser = new OSMParser(processor, true);
						Reader reader = new InputStreamReader(is, Charset.forName("UTF-8"));
						parser.setReader(reader);
						try {
							parser.parse();
						} finally {
							reader.close();
						}
					}
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
	}



	/**
	 * Read the index and set corresponding fields.
	 */
	private void init() {
		if (precompSeaDir.exists()){

			String internalPath = null;    	
			InputStream indexStream = null;
			String indexFileName = "index.txt.gz";
			try{
				if (precompSeaDir.isDirectory()){
					File indexFile = new File(precompSeaDir, indexFileName);
					if (indexFile.exists() == false) {
						// check if the unzipped index file exists
						indexFileName = "index.txt";
						indexFile = new File(precompSeaDir, indexFileName);
					}
					if (indexFile.exists()) {
						indexStream = new FileInputStream(indexFile);
					}
				} else if (precompSeaDir.getName().endsWith(".zip")){
					zipFile = new ZipFile(precompSeaDir);
					internalPath = "sea";
					ZipEntry entry = zipFile.getEntry(internalPath);
					if (entry == null)
						internalPath = "";
					else 
						internalPath = internalPath + "/";
					entry = zipFile.getEntry(internalPath + indexFileName);
					if (entry == null){
						indexFileName = "index.txt";
						entry = zipFile.getEntry(internalPath + indexFileName);
					}
					if (entry != null){
						indexStream = zipFile.getInputStream(entry);
					}
				} else {
					System.err.println("Don't know how to read " + precompSeaDir);
				}
				if (indexStream != null){
					if (indexFileName.endsWith(".gz")) {
						indexStream = new GZIPInputStream(indexStream);
					}
					try{
						loadIndex(indexStream);
					} catch (IOException exp) {
						System.err.println("Cannot read index file " + indexFileName + " " + 
								exp);
					}

					if (zipFile != null){
						precompZipFileInternalPath = internalPath;
					}
					indexStream.close();
				}
			} catch (IOException exp) {
				System.err.println("Cannot read index file " + indexFileName + " " + 
						exp);

			}
		} else {
			System.err.println("Directory or zip file with precompiled sea does not exist: "
					+ precompSeaDir.getName());
		}
	}
	
    /**
     * Read the index from stream and populate the index grid. 
     * @param fileStream already opened stream
     */
    private void loadIndex(InputStream fileStream) throws IOException{
		int indexWidth = (PrecompSeaReader.getPrecompTileStart(MAX_LON) - PrecompSeaReader.getPrecompTileStart(MIN_LON)) / PrecompSeaReader.PRECOMP_RASTER;
		int indexHeight = (PrecompSeaReader.getPrecompTileStart(MAX_LAT) - PrecompSeaReader.getPrecompTileStart(MIN_LAT)) / PrecompSeaReader.PRECOMP_RASTER;
		LineNumberReader indexReader = new LineNumberReader(
				new InputStreamReader(fileStream));
		Pattern csvSplitter = Pattern.compile(Pattern
				.quote(";"));
		String indexLine = null;

		byte[][] indexGrid = new byte[indexWidth+1][indexHeight+1];
		boolean detectExt = true; 
		String prefix = null;
		String ext = null;

		while ((indexLine = indexReader.readLine()) != null) {
			if (indexLine.startsWith("#")) {
				// comment
				continue;
			}
			String[] items = csvSplitter.split(indexLine);
			if (items.length != 2) {
				System.out.println("Invalid format in index file name: " + 
						indexLine);
				continue;
			}
			String precompKey = items[0];
			byte type = updatePrecompSeaTileIndex(precompKey, items[1], indexGrid);
			if (type == '?'){
				System.out.println("Invalid format in index file name: " + 
						indexLine);
				continue;
			}
			if (type == MIXED_TILE){
				// make sure that all file names are using the same name scheme
				int prePos = items[1].indexOf(items[0]);
				if (prePos >= 0){
					if (detectExt){
						prefix = items[1].substring(0, prePos);
						ext = items[1].substring(prePos+items[0].length());
						detectExt = false;
					} else {
						StringBuilder sb = new StringBuilder(prefix);
						sb.append(precompKey);
						sb.append(ext);												
						if (items[1].equals(sb.toString()) == false){
							System.out.println("Unexpected file name in index file: " + 
									indexLine);
						}
					}
				}
			}

		}
		// 
		precompIndex = indexGrid;
		precompSeaPrefix = prefix;
		precompSeaExt = ext;
    }

    private InputStream getStream(String tileName){
    	InputStream is = null;
    	try{
    		if (zipFile != null){
    			ZipEntry entry = zipFile.getEntry(precompZipFileInternalPath + tileName);
    			if (entry != null){
    				is = zipFile.getInputStream(entry);
    			} else {
    				System.err.println("Preompiled sea tile " + tileName + " not found."); 								
    			}
    		} else {
    			File precompTile = new File(precompSeaDir,tileName);
    			is = new FileInputStream(precompTile);
    		}
    	} catch (FileNotFoundException exp) {
    		System.err.println("Preompiled sea tile " + tileName + " not found."); 
    	} catch (Exception exp) {
    		System.err.println(exp);
    		exp.printStackTrace();
    	}
		return is;
    }
    
    /**
     * Retrieves the start value of the precompiled tile.
     * @param value the value for which the start value is calculated
     * @return the tile start value
     */
    private static int getPrecompTileStart(int value) {
    	int rem = value % PRECOMP_RASTER;
    	if (rem == 0) {
    		return value;
    	} else if (value >= 0) {
    		return value - rem;
    	} else {
    		return value - PRECOMP_RASTER - rem;
    	}
    }

	/**
	 * Retrieves the end value of the precompiled tile.
	 * @param value the value for which the end value is calculated
	 * @return the tile end value
	 */
	private static int getPrecompTileEnd(int value) {
		int rem = value % PRECOMP_RASTER;
		if (rem == 0) {
			return value;
		} else if (value >= 0) {
			return value + PRECOMP_RASTER - rem;
		} else {
			return value - rem;
		}
	}	
	
	/**
	 * Calculates the key names of the precompiled sea tiles for the bounding box.
	 * The key names are compiled of {@code lat+"_"+lon}.
	 * @return the key names for the bounding box
	 */
	private List<String> getPrecompKeyNames() {
		List<String> precompKeys = new ArrayList<String>();
		for (int lat = getPrecompTileStart(bounds.getMinLat()); lat < getPrecompTileEnd(bounds
				.getMaxLat()); lat += PRECOMP_RASTER) {
			for (int lon = getPrecompTileStart(bounds.getMinLong()); lon < getPrecompTileEnd(bounds
					.getMaxLong()); lon += PRECOMP_RASTER) {
				int latIndex = (MAX_LAT-lat) / PRECOMP_RASTER;
				int lonIndex = (MAX_LON-lon) / PRECOMP_RASTER;
				byte type = precompIndex[lonIndex][latIndex]; 
				if (type == MIXED_TILE)
					precompKeys.add(precompSeaPrefix + lat + "_" + lon + precompSeaExt);
			}
		}
		return precompKeys;
	}
	
	/**
	 * Update the index grid for the element identified by precompKey. 
	 * @param precompKey The key name is compiled of {@code lat+"_"+lon}. 
	 * @param fileName either "land", "sea", or a file name containing OSM data
	 * @param indexGrid the previously allocated index grid  
	 * @return the byte that was saved in the index grid 
	 */
	private byte updatePrecompSeaTileIndex (String precompKey, String fileName, byte[][] indexGrid){
		String[] tileCoords = keySplitter.split(precompKey);
		byte type = '?';
		if (tileCoords.length == 2){
			int lat = Integer.valueOf(tileCoords[0]); 
			int lon = Integer.valueOf(tileCoords[1]); 
			int latIndex = (MAX_LAT - lat) / PRECOMP_RASTER;
			int lonIndex = (MAX_LON - lon) / PRECOMP_RASTER;

			if ("sea".equals(fileName))
				type = SEA_TILE;
			else if ("land".equals(fileName))
				type = LAND_TILE;
			else 
				type = MIXED_TILE;

			indexGrid[lonIndex][latIndex] = type;
		}
		return type;
	}
	
}
