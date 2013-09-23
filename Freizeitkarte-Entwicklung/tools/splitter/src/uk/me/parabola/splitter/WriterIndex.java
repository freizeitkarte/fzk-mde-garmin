/*
 * Copyright (c) 2012.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */

package uk.me.parabola.splitter;

/**
 * 
 * @author GerdP
 *
 */
public interface WriterIndex{
	/**
	 * @return the bounding box of the writer areas.
	 */
	public Area getBounds();
	/**
	 * Return a set of writer candidates for this node. 
	 * @param n the node
	 * @return a reference to a static WriterGridResult instance
	 */
	public WriterGridResult get (final Node n);

	/**
	 * Return a set of writer candidates for these coordinates
	 * @param lat the latitude value in map units
	 * @param lon the longitude value in map units
	 * @return a reference to a static WriterGridResult instance 
	 */
	public WriterGridResult get (int lat, int lon);

}
