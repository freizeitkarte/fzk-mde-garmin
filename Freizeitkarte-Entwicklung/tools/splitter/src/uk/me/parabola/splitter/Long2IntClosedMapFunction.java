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
 * Stores long/int pairs. Only useful with data that is already in key-sorted order.
 * 
 */
interface Long2IntClosedMapFunction {
	/**
	 * Add a new pair. The key must be higher than then any existing key in the map.  
	 * @param key the key value
	 * @param val the value
	 * @return the position in which the key was inserted
	 */
	public int add(long key, int val);
	/**
	 * Get the value for the key. 
	 * @param key
	 * @return
	 */
	public int getRandom(long key);
	/**
	 * Get the value for the key from a map that was written to temporary
	 * file. 
	 * @param key the key
	 * @return unassigned if the current key is higher, the vaue if the key matches  
	 */
	public int getSeq(long key);
	
	public long size();
	public int defaultReturnValue();
	/**
	 * 	Remove temp files if they exist. 
	 */
	void finish();
	
	/** 
	 * Cclose the temp file, reset the current values. Use this to start
	 * from the beginning.
	 * @throws IOException
	 */
	public void close() throws IOException;
	
	/**
	 * Move the data stored in the map to a temp file. This makes the map read only
	 * and allows only sequential access. 
	 * @param directory
	 * @throws IOException
	 */
	void switchToSeqAccess(File directory) throws IOException;
	/**
	 * Return the position of the key if found in the map 
	 * @param key 
	 * @return the position or a negative value to indicate "not found"
	 */
	public int getKeyPos(long key);
	/**
	 * Replace the value for an existing key.
	 * @param key
	 * @param val
	 * @return the previously stored value
	 */
	public int replace(long key, int val);
	public void stats(final String prefix);
}
