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

//import it.unimi.dsi.fastutil.longs.Long2ShortFunction;

/**
 * Stores long/short pairs. 
 * 
 */
interface SparseLong2ShortMapFunction {
	final short UNASSIGNED = Short.MIN_VALUE;
	public short put(long key, short val);
	public void clear();
	public boolean containsKey(long key);
	public short get(long key);
	public void stats(int msgLevel);
	public long size();
	public short defaultReturnValue();
	public void defaultReturnValue(short arg0);
}
