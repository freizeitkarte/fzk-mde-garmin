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
 * Builds up a density map.
 */
class DensityMapCollector extends AbstractMapProcessor{
	private final DensityMap densityMap;
	private final MapDetails details = new MapDetails();
	private Area bounds;

	DensityMapCollector(int resolution) {
		Area bounds = new Area(-0x400000, -0x800000, 0x400000, 0x800000);
		densityMap = new DensityMap(bounds, resolution);
	}

	@Override
	public boolean isStartNodeOnly() {
		return true;
	}
	@Override
	public boolean skipTags() {
		return true;
	}
	@Override
	public boolean skipWays() {
		return true;
	}
	@Override
	public boolean skipRels() {
		return true;
	}

	@Override
	public void boundTag(Area bounds) {
		if (this.bounds == null)
			this.bounds = bounds;
		else
			this.bounds = this.bounds.add(bounds);
	}

	@Override
	public void processNode(Node n) {
		int glat = n.getMapLat();
		int glon = n.getMapLon();
		densityMap.addNode(glat, glon);
		details.addToBounds(glat, glon);
	}

	public Area getExactArea() {
		if (bounds != null) {
			return bounds;
		} else {
			return details.getBounds();
		}
	}
	public SplittableDensityArea getRoundedArea(int resolution) {
		Area bounds = RoundingUtils.round(getExactArea(), resolution);
		return new SplittableDensityArea(densityMap.subset(bounds));
	} 

	public void mergeSeaData(DensityMapCollector seaData, boolean trim) {
		densityMap.mergeSeaData(seaData.densityMap, getExactArea(), trim);
	}

	public void saveMap(String fileName) {
		if (bounds != null && details != null && details.getBounds() != null)
			densityMap.saveMap(fileName, details.getBounds(), bounds);
	}
	public void readMap(String fileName) {
		bounds = densityMap.readMap(fileName, details);
	}

}
