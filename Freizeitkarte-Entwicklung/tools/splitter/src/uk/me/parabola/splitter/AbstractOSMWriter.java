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
import java.io.File;

public abstract class AbstractOSMWriter implements OSMWriter{
	
	protected final Area bounds;
	protected final Area extendedBounds;
	protected final File outputDir;
	protected final int mapId;
	protected final Rectangle bbox; 
	

	public AbstractOSMWriter(Area bounds, File outputDir, int mapId, int extra) {
		this.mapId = mapId;
		this.bounds = bounds;
		this.outputDir = outputDir;
		extendedBounds = new Area(bounds.getMinLat() - extra,
				bounds.getMinLong() - extra,
				bounds.getMaxLat() + extra,
				bounds.getMaxLong() + extra);
		this.bbox = Utils.area2Rectangle(bounds, 1);
	}

	public Area getBounds() {
		return bounds;
	}
	
	public Area getExtendedBounds() {
		return extendedBounds;
	}
	public int getMapId(){
		return mapId;
	}
	
	public Rectangle getBBox(){
		return bbox;
	}
	
	public boolean nodeBelongsToThisArea(Node node) {
		return (extendedBounds.contains(node.getMapLat(), node.getMapLon()));
	}

	public boolean coordsBelongToThisArea(int mapLat, int mapLon) {
		return (extendedBounds.contains(mapLat,mapLon));
	}
	
	public boolean areaIsPseudo(){
		return false;
	}
}
