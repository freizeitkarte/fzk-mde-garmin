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

import java.util.ArrayList;
import java.util.BitSet;
import java.util.HashMap;

/**
 * Maps a BitSet containing the used writers to an integer value.  
 * An OSM element is written to one or more writers. Every used
 * combination of writers is translated to an integer.
 * Use this dictionary if you expect many different writer combinations,
 * e.g. for relations and their members.
 * @author GerdP
 *
 */
public class WriterDictionaryInt{
	public final static int UNASSIGNED = -1;
	private final ArrayList<BitSet> sets; 
	private final int numOfWriters;
	private final HashMap<BitSet, Integer> index;
	
	/** 
	 * Create a dictionary for a given number of writers
	 * @param numOfWriters the number of writers that are used
	 */
	WriterDictionaryInt (OSMWriter [] writers){
		this.numOfWriters = writers.length;
		sets = new ArrayList<BitSet>();
		index = new HashMap<BitSet, Integer>();
		init();
	}
	
	/**
	 * initialize the dictionary with sets containing a single writer.
	 */
	private void init(){
		ArrayList<BitSet> writerSets = new ArrayList<BitSet>(numOfWriters);
		for (int i=0; i < numOfWriters; i++){
			BitSet b = new BitSet();
			b.set(i);
			translate(b);
			writerSets.add(b);
		}
	}
	
	/**
	 * Calculate the integer value for a given BitSet. The BitSet must not 
	 * contain values higher than numOfWriters.
	 * @param writerSet the BitSet 
	 * @return an int value that identifies this BitSet 
	 */
	public int translate(final BitSet writerSet){
		Integer combiIndex = index.get(writerSet);
		if (combiIndex == null){
			BitSet bnew = new BitSet();

			bnew.or(writerSet);
			combiIndex = sets.size();
			sets.add(bnew);
			index.put(bnew, combiIndex);
		}
		return combiIndex;
	}

	/**
	 * Return the BitSet that is related to the int value.
	 * The caller must make sure that the idx is valid.
	 * @param idx an int value that was returned by the translate() 
	 * method.  
	 * @return the BitSet
	 */
	public BitSet getBitSet (final int idx){
		return sets.get(idx);
	}
	
	/**
	 * return the number of sets in this dictionary 
	 * @return the number of sets in this dictionary
	 */
	public int size(){
		return sets.size();
	}

	public int getNumOfWriters(){
		return numOfWriters;
	}

	/**
	 * return the id of a single writer or 
	 * @param writerIdx
	 * @return
	 */
	public boolean isSingleWriterIdx(int writerIdx) {
		return (writerIdx < numOfWriters);
	}

}
