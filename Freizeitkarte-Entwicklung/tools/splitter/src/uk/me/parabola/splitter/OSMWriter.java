/*
 * Copyright (c) 2009.
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

import java.awt.Rectangle;
import java.io.IOException;

public interface OSMWriter {
	/** 
	 * @return the bounds of the area (excluding the overlap)
	 */
	public Area getBounds();
	
	/**
	 * @return the bounds of the area (including the overlap)
	 */
	public Area getExtendedBounds();
	
	public Rectangle getBBox();
	
	public int getMapId();
	
	/**
	 * open output file, allocate buffers etc.
	 */
	public abstract void initForWrite();

	/**
	 * close output file, free resources
	 */
	public abstract void finishWrite();

	public boolean nodeBelongsToThisArea(Node node);

	public boolean coordsBelongToThisArea(int mapLat, int mapLon);
	
	public abstract void write(Node node) throws IOException;

	public abstract void write(Way way) throws IOException;

	public abstract void write(Relation rel) throws IOException;

	/**
	 * @return true if the area was added for the problem list generator
	 */
	public boolean areaIsPseudo();
}
