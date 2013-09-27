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

import it.unimi.dsi.fastutil.ints.Int2LongOpenHashMap;
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap;

/** A partly BitSet implementation optimized for memory 
 * when used to store very large values with a high likelihood 
 * that the stored values build groups like e.g. the OSM node IDs.
 * The keys are divided into 3 parts.
 * The 1st part is stored in a small hash map.
 * The 2nd part is stored in larger hash maps addressing long values. 
 * The 3rd part (6 bits) is stored in the long value addressed by the upper maps.  
 * author GerdP */ 
public class SparseBitSet{
	private static final long MID_ID_MASK = 0x7ffffff;
	private static final long TOP_ID_MASK = ~MID_ID_MASK;  
	private static final int LOW_MASK = 63; 						
	private static final int TOP_ID_SHIFT = Long.numberOfTrailingZeros(TOP_ID_MASK);  
	private static final int MID_ID_SHIFT = Integer.numberOfTrailingZeros(~LOW_MASK);  

	private Long2ObjectOpenHashMap<Int2LongOpenHashMap> topMap = new Long2ObjectOpenHashMap<Int2LongOpenHashMap>();
	private int setBits;
  
  public void set(long key){
      long topId = key >> TOP_ID_SHIFT;
      Int2LongOpenHashMap midMap = topMap.get(topId);
      if (midMap == null){
    	  midMap = new Int2LongOpenHashMap();
    	  topMap.put(topId, midMap);
      }
      int midId = (int)((key & MID_ID_MASK) >> MID_ID_SHIFT);
      long chunk = midMap.get(midId);
      int bitPos =(int)(key & LOW_MASK);
      long val = 1L << (bitPos-1);  
      if (chunk != 0){
    	  if ((chunk & val) != 0)
    		  return;
          val |= chunk;
      }
      midMap.put(midId, val); 
      ++setBits;
  }

  public void clear(long key){
      long topId = key >> TOP_ID_SHIFT;
      Int2LongOpenHashMap midMap = topMap.get(topId);
      if (midMap == null)
    	  return;
      int midId = (int)((key & MID_ID_MASK) >> MID_ID_SHIFT);
      long chunk = midMap.get(midId);
      if (chunk == 0)
          return;
      int bitPos =(int)(key & LOW_MASK);
      long val = 1L << (bitPos-1);  
      if ((chunk & val) == 0)
    	  return;
      chunk &= ~val;
      if (chunk == 0){
    	  midMap.remove(midId);
    	  if (midMap.isEmpty()){
    		  topMap.remove(topId);
    	  }
      }
      else 
    	  midMap.put(midId, chunk);
      --setBits;
  }
  
  public boolean get(long key){
      long topId = key >> TOP_ID_SHIFT;
      Int2LongOpenHashMap midMap = topMap.get(topId);
      if (midMap == null)
    	  return false;
      int midId = (int)((key & MID_ID_MASK) >> MID_ID_SHIFT);
      long chunk = midMap.get(midId);
      if (chunk == 0)
          return false;
      int bitPos =(int)(key & LOW_MASK);
      long val = 1L << (bitPos-1);  
      return ((chunk & val) != 0);
  }

  public void clear(){
	  topMap.clear();
	  setBits = 0;
  }
  
  public int cardinality(){
	  return setBits;
  }
}

                                                                           