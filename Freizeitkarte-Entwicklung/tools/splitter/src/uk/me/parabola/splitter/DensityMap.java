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
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.util.regex.Pattern;

/**
 * Builds up a map of node densities across the total area being split.
 * Density information is held at the maximum desired map resolution.
 * Every step up in resolution increases the size of the density map by
 * a factor of 4.
 *
 * @author Chris Miller
 */
public class DensityMap {
	private static final int SEA_NODE_FACTOR = 2;
	private final int width, height, shift;
	private final int[][] nodeMap;
	private Area bounds;
	private long totalNodeCount;

	/**
	 * Creates a density map.
	 * @param area the area that the density map covers.
	 * @param resolution the resolution of the density map. This must be a value between 1 and 24.
	 */
	public DensityMap(Area area, int resolution) {
		assert resolution >=1 && resolution <= 24;
		shift = 24 - resolution;

		bounds = RoundingUtils.round(area, resolution);
		height = bounds.getHeight() >> shift;
		width = bounds.getWidth() >> shift;
		nodeMap = new int[width][];
	}

	/**
	 * @param polygonArea the polygon area 
	 * @return an area with rectilinear shape that approximates the polygon area 
	 */
	public java.awt.geom.Area rasterPolygon(java.awt.geom.Area polygonArea){
		if (polygonArea == null)
			return null;
		java.awt.geom.Area simpleArea = new java.awt.geom.Area();
		if (polygonArea.intersects(Utils.area2Rectangle(bounds, 0)) == false)
			return simpleArea;
		int gridElemWidth = bounds.getWidth() / width;
		int gridElemHeight= bounds.getHeight()/ height;
		Rectangle polygonBbox = polygonArea.getBounds();
		int minLat = Math.max((int)polygonBbox.getMinY(), bounds.getMinLat());
		int maxLat = Math.min((int)polygonBbox.getMaxY(), bounds.getMaxLat());
		int minY = latToY(minLat);
		int maxY = latToY(maxLat);
		assert minY >= 0 && minY <= height;
		assert maxY >= 0 && maxY <= height;
		for (int x = 0; x < width; x++) {
			int lon = xToLon(x);
			if (lon + gridElemWidth < polygonBbox.getMinX() 
					|| lon > polygonBbox.getMaxX()
					|| polygonArea.intersects(lon, polygonBbox.getMinY(), gridElemWidth, polygonBbox.getHeight()) == false){
				continue;
			}
			int firstY = -1;
			for (int y = 0; y < height; y++) {
				int lat = yToLat(y);
				if (y < minY || y > maxY 
						|| polygonArea.intersects(lon, lat, gridElemWidth, gridElemHeight) == false){
					if (firstY >= 0){
						simpleArea.add(new java.awt.geom.Area(new Rectangle(x,firstY,1,y-firstY)));
						firstY = -1; 
					}
				} else {
					if (firstY < 0)
						firstY = y; 
				}
			}
			if (firstY >= 0){
				simpleArea.add(new java.awt.geom.Area(new Rectangle(x,firstY,1,height-firstY)));
			}
		}
		return simpleArea;
	}
	
	public int getShift() {
		return shift;
	}

	public Area getBounds() {
		return bounds;
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public int addNode(int lat, int lon) {
		if (!bounds.contains(lat, lon))
			return 0;

		totalNodeCount++;
		int x = lonToX(lon);
		if (x == width)
			x--;
		int y = latToY(lat);
		if (y == height)
			y--;

		if (nodeMap[x] == null)
			nodeMap[x] = new int[height];
		return ++nodeMap[x][y];
	}

	public long getNodeCount() {
		return totalNodeCount;
	}

	public int getNodeCount(int x, int y) {
		return nodeMap[x] != null ? nodeMap[x][y] : 0;
	}

	public int[][] getyxMap(){
		int[][] yxMap = new int[height][];
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				int count = (nodeMap[x] == null) ? 0:nodeMap[x][y];
				if (count > 0) {
					if (yxMap[y] == null)
						yxMap[y] = new int[width];
					yxMap[y][x] = count;
				}
			}
		}
		return yxMap;
	}
	
	public DensityMap subset(final Area subsetBounds) {
		int minLat = Math.max(bounds.getMinLat(), subsetBounds.getMinLat());
		int minLon = Math.max(bounds.getMinLong(), subsetBounds.getMinLong());
		int maxLat = Math.min(bounds.getMaxLat(), subsetBounds.getMaxLat());
		int maxLon = Math.min(bounds.getMaxLong(), subsetBounds.getMaxLong());

		// If the area doesn't intersect with the density map, return an empty map
		if (minLat > maxLat || minLon > maxLon) {
			return new DensityMap(Area.EMPTY, 24 - shift);
		}

		Area subset = new Area(minLat, minLon, maxLat, maxLon);
		// If there's nothing in the area return an empty map
		if (subset.getWidth() == 0 || subset.getHeight() == 0) {
			return new DensityMap(Area.EMPTY, 24 - shift);
		}

		DensityMap result = new DensityMap(subset, 24 - shift);

		int startX = lonToX(subset.getMinLong());
		int startY = latToY(subset.getMinLat());
		int maxX = subset.getWidth() >> shift;
		int maxY = subset.getHeight() >> shift;
		for (int x = 0; x < maxX; x++) {
			if (startY == 0 && maxY == height) {
				result.nodeMap[x] = nodeMap[startX + x];
			} else if (nodeMap[startX + x] != null) {
				result.nodeMap[x] = new int[maxY];
				try {
					System.arraycopy(nodeMap[startX + x], startY, result.nodeMap[x], 0, maxY);
				} catch (ArrayIndexOutOfBoundsException e) {
					System.out.println("subSet() died at " + startX + ',' + startY + "  " + maxX + ',' + maxY + "  " + x);
				}
			}
			for (int y = 0; y < maxY; y++) {
				if (result.nodeMap[x] != null)
					result.totalNodeCount += result.nodeMap[x][y];
			}
		}
		return result;
	}

	private int yToLat(int y) {
		return (y << shift) + bounds.getMinLat();
	}

	private int xToLon(int x) {
		return (x << shift) + bounds.getMinLong();
	}

	private int latToY(int lat) {
		return lat - bounds.getMinLat() >>> shift;
	}

	private int lonToX(int lon) {
		return lon - bounds.getMinLong() >>> shift;
	}

	/**
	 * For debugging, to be removed. 
	 * @param fileName
	 * @param detailBounds
	 * @param collectorBounds
	 */
	public void saveMap(String fileName, Area detailBounds, Area collectorBounds) {
		try {
			FileWriter f = new FileWriter(new File(fileName));
			f.write(detailBounds.getMinLat() + "," + detailBounds.getMinLong() + "," + detailBounds.getMaxLat() + "," + detailBounds.getMaxLong() + '\n');
			f.write(collectorBounds.getMinLat() + "," + collectorBounds.getMinLong() + "," + collectorBounds.getMaxLat() + "," + collectorBounds.getMaxLong() + '\n');
			//f.write(bounds.getMinLat() + "," + bounds.getMinLong() + "," + bounds.getMaxLat() + "," + bounds.getMaxLong() + '\n');
			for (int x=0; x<width; x++){
				if (nodeMap[x] != null){
					for (int y=0; y<height; y++){
						if (nodeMap[x][y] != 0)
							f.write(x+ "," + y + "," + nodeMap[x][y] + '\n');
					}
				}
			}
			f.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * For debugging, to be removed.
	 * @param fileName
	 * @param details
	 * @return
	 */
	public Area readMap(String fileName, MapDetails details) {
		File mapFile = new File(fileName);
		Area collectorBounds = null;
		if (!mapFile.exists()) {
			System.out.println("Error: map file doesn't exist: " + mapFile);  
			return null;
		}
		try {
			InputStream fileStream = new FileInputStream(mapFile);
			LineNumberReader problemReader = new LineNumberReader(
					new InputStreamReader(fileStream));
			Pattern csvSplitter = Pattern.compile(Pattern.quote(","));
			
			String problemLine;
			String[] items;
			problemLine = problemReader.readLine();
			if (problemLine != null){
				items = csvSplitter.split(problemLine);
				if (items.length != 4){
					System.out.println("Error: Invalid format in map file, line number " + problemReader.getLineNumber() + ": "   
							+ problemLine);
					problemReader.close();
					return null;
				}
				details.addToBounds(Integer.parseInt(items[0]), Integer.parseInt(items[1]));
				details.addToBounds(Integer.parseInt(items[2]),Integer.parseInt(items[3]));
			}
			problemLine = problemReader.readLine();
			if (problemLine != null){
				items = csvSplitter.split(problemLine);
				if (items.length != 4){
					System.out.println("Error: Invalid format in map file, line number " + problemReader.getLineNumber() + ": "   
							+ problemLine);
					problemReader.close();
					return null;
				}
				collectorBounds = new Area(Integer.parseInt(items[0]), Integer.parseInt(items[1]),
						Integer.parseInt(items[2]),Integer.parseInt(items[3]));
			}
			while ((problemLine = problemReader.readLine()) != null) {
				items = csvSplitter.split(problemLine);
				if (items.length != 3) {
					System.out.println("Error: Invalid format in map file, line number " + problemReader.getLineNumber() + ": "   
							+ problemLine);
					problemReader.close();
					return null;
				}
				int x,y,sum;
				try{
					x = Integer.parseInt(items[0]);
					y = Integer.parseInt(items[1]);
					sum = Integer.parseInt(items[2]);
				
					if (x < 0 || x >= width || y < 0 || y>=height){
						System.out.println("Error: Invalid data in map file, line number " + + problemReader.getLineNumber() + ": "   
								+ problemLine);

					}
					else{
						if (nodeMap[x] == null)
							nodeMap[x] = new int[height];
						nodeMap[x][y] = sum;
						totalNodeCount += sum;
					}
				}
				catch(NumberFormatException exp){
					System.out.println("Error: Invalid number format in problem file, line number " + + problemReader.getLineNumber() + ": "   
							+ problemLine + exp);
					problemReader.close();
					return null;
				}
			}
			problemReader.close();
		} catch (IOException exp) {
			System.out.println("Error: Cannot read problem file " + mapFile +  
					exp);
			return null;
		}
		return collectorBounds;
	}

	public Area getArea(int x, int y, int width2, int height2) {
		assert x >= 0;
		assert y >= 0;
		assert width2 > 0;
		assert height2 > 0;
		Area area = new Area(yToLat(y),xToLon(x),yToLat(y+height2),xToLon(x+width2));
		return area;
	}

	/**
	 * Handle data that will be added with the --precomp-sea option of mkgmap.
	 * We add coast line data only to empty parts to avoid counting it twice.
	 * @param seaData a DensityMap that was filled with data from precompiled sea 
	 * @param area 
	 */
	public void mergeSeaData(DensityMap seaData, Area area, boolean trim) {
		if (this.shift != seaData.shift
				|| Utils.area2Rectangle(bounds, 0).equals(
						Utils.area2Rectangle(seaData.getBounds(), 0)) == false) {
			System.err.println("cannot merge density maps");
			System.exit(-1);
		}
		if (trim && totalNodeCount == 0)
			return;
		int minX = lonToX(area.getMinLong()); 
		int maxX = lonToX(area.getMaxLong());
		int minY = latToY(area.getMinLat());
		int maxY = latToY(area.getMaxLat());
		if (trim){
			for (int x = minX; x <= width; x++) {
				if (nodeMap[x] != null){
					minX = x;
					break;
				}
			}
			for (int x = maxX; x >= 0; x--) {
				if (nodeMap[x] != null){
					maxX = x;
					break;
				}
			}
			boolean done = false;
			for (int y = minY; y < height; y++) {
				for (int x = minX; x < width; x++) {
					if (nodeMap[x] == null)
						continue;
					if (nodeMap[x][y] > 0){
						minY = y;
						done = true;
						break;
					}
				}
				if (done)
					break;
			}
			done = false;
			for (int y = maxY; y >= 0; y--) {
				for (int x = minX; x < width; x++) {
					if (nodeMap[x] == null)
						continue;
					if (nodeMap[x][y] > 0){
						maxY = y;
						done = true;
						break;
					}
				}
				if (done)
					break;
			}
		}
		long addedSeaNodes = 0;
		for (int x = minX; x <= maxX; x++){
			int[] seaCol = seaData.nodeMap[x];
			if (seaCol == null)
				continue;
			int[] col = nodeMap[x];
			if (col == null)
				col = new int[height];
			for (int y = minY; y <= maxY; y++){
				if (col[y] == 0){
					int seaCount = seaCol[y] * SEA_NODE_FACTOR;
					if (seaCount > 0){
						col[y] = seaCount;
						totalNodeCount += seaCount;
						addedSeaNodes += seaCount;
					}
				}
			}
		}
		System.out.println("Added " + addedSeaNodes + " nodes from precompiled sea data.");
	}
}

