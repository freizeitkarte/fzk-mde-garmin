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

import java.io.File;
import java.io.IOException;

/**
 * Stores data that is needed in different passes of the program.
 * @author GerdP
 *
 */
public class DataStorer{
	public static final int NODE_TYPE = 0;
	public static final int WAY_TYPE = 1;
	public static final int REL_TYPE = 2;
	
	private final int numOfWriters;
	private final Long2IntClosedMapFunction[] maps = new Long2IntClosedMapFunction[3];
	
	private final WriterDictionaryShort writerDictionary;
	private final WriterDictionaryInt multiTileWriterDictionary;
	private final WriterIndex writerIndex;
	private SparseLong2ShortMapFunction usedWays = null;
	private final OSMId2ObjectMap<Integer> usedRels = new OSMId2ObjectMap<Integer>();
	private boolean idsAreNotSorted;

	/** 
	 * Create a dictionary for a given number of writers
	 * @param numOfWriters the number of writers that are used
	 */
	DataStorer (OSMWriter [] writers){
		this.numOfWriters = writers.length;
		this.writerDictionary = new WriterDictionaryShort(writers);
		this.multiTileWriterDictionary = new WriterDictionaryInt(writers);
		this.writerIndex = new WriterGrid(writerDictionary);
		return;
	}

	public int getNumOfWriters(){
		return numOfWriters;
	}

	public WriterDictionaryShort getWriterDictionary() {
		return writerDictionary;
	}

	
	public void setWriterMap(int type, Long2IntClosedMapFunction nodeWriterMap){
		maps[type] = nodeWriterMap;
	}
	public Long2IntClosedMapFunction getWriterMap(int type){
		return maps[type];
	}
	
	public WriterIndex getGrid() {
		return writerIndex;
	}

	public WriterDictionaryInt getMultiTileWriterDictionary() {
		return multiTileWriterDictionary;
	}

	public SparseLong2ShortMapFunction getUsedWays() {
		return usedWays;
	}

	public OSMId2ObjectMap<Integer> getUsedRels() {
		return usedRels;
	}

	public void setUsedWays(SparseLong2ShortMapFunction ways) {
		usedWays = ways;
	}

	public boolean isIdsAreNotSorted() {
		return idsAreNotSorted;
	}

	public void setIdsAreNotSorted(boolean idsAreNotSorted) {
		this.idsAreNotSorted = idsAreNotSorted;
	}

	public void restartWriterMaps() {
		for (Long2IntClosedMapFunction map: maps){
			if (map != null){
				try {
					map.close();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}

	}

	public void switchToSeqAccess(File fileOutputDir) throws IOException {
		boolean msgWritten = false;
		long start = System.currentTimeMillis();
		for (Long2IntClosedMapFunction map: maps){
			if (map != null){
				if (!msgWritten){
					System.out.println("Writing results of MultiTileAnalyser to temp files ...");
					msgWritten = true;
				}
				map.switchToSeqAccess(fileOutputDir);
			}
		}		
		System.out.println("Writing temp files took " + (System.currentTimeMillis()-start) + " ms");
	}

	public void finish() {
		for (Long2IntClosedMapFunction map: maps){
			if (map != null)
				map.finish();
		}		
	}

	public void stats(final String prefix) {
		for (Long2IntClosedMapFunction map: maps){
			if (map != null)
				map.stats(prefix);
		}		
		
	}
}
