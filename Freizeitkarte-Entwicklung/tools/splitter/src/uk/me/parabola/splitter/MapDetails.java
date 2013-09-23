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

/**
 * The map features that we are going to map are collected here.
 *
 * @author Steve Ratcliffe
 */
public class MapDetails {
	private int minLat = Utils.toMapUnit(180.0);
	private int minLon = Utils.toMapUnit(180.0);
	private int maxLat = Utils.toMapUnit(-180.0);
	private int maxLon = Utils.toMapUnit(-180.0);

	/**
	 * Add the given point to the total bounds for the map.
	 *
	 * @param lat the latitude, in map units.
	 * @param lon the longitude, in map units.
	 */
	public void addToBounds(int lat, int lon) {
		if (lat < minLat)
			minLat = lat;
		if (lat > maxLat)
			maxLat = lat;
		if (lon < minLon)
			minLon = lon;
		if (lon > maxLon)
			maxLon = lon;
	}

	/**
	 * Get the bounds of this map.
	 *
	 * @return An area covering all the points in the map.
	 */
	public Area getBounds() {
		return new Area(minLat, minLon, maxLat, maxLon);
	}
}