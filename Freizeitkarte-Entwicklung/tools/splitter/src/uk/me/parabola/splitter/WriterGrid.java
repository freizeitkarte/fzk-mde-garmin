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

import java.util.BitSet;

/**
 * A grid that covers the area covered by all writers. Each grid element contains 
 * information about the tiles that are intersecting the grid element and whether 
 * the grid element lies completely within such a tile area.
 * This is used to minimize the needed tests when analyzing coordinates of node coordinates.
 * @author GerdP
 *
 */
public class WriterGrid implements WriterIndex{
	private final Area bounds;
	private final Grid grid;
	private final WriterGridResult r;
	private final WriterDictionaryShort writerDictionary;

	/**
	 * Create a grid to speed up the search of writer candidates.
	 * @param writerDictionary 
	 * @param withOuter 
	 */
	WriterGrid(WriterDictionaryShort writerDictionary){
		this.writerDictionary = writerDictionary;  
		r = new WriterGridResult();
		long start = System.currentTimeMillis();

		grid = new Grid(null, null);
		bounds = grid.getBounds();
		
		System.out.println("Grid(s) created in " + (System.currentTimeMillis() - start) + " ms");
	}

	public Area getBounds(){
		return bounds;
	}

	public WriterGridResult get (final Node n){
		return grid.get(n.getMapLat(),n.getMapLon());
	}

	public WriterGridResult get (int lat, int lon){
		return grid.get(lat, lon);
	}

	private class Grid {
		private final static int TOP_GRID_DIM_LON = 512; 
		private final static int TOP_GRID_DIM_LAT = 512;
		private final static int SUB_GRID_DIM_LON = 32; 
		private final static int SUB_GRID_DIM_LAT = 32;
		private static final int MIN_GRID_LAT = 2048;
		private static final int MIN_GRID_LON = 2048;
		private static final int MAX_TESTS = 10; 
		private int gridDivLon, gridDivLat;
		private int gridMinLat, gridMinLon; 
		// bounds of the complete grid
		private Area bounds = null;
		private short [][] grid;
		private boolean [][] testGrid;
		private Grid[][] subGrid = null; 
		private final int maxCompares;
		private int usedSubGridElems = 0;
		private final int gridDimLon;
		private final int gridDimLat;

		public Grid(BitSet UsedWriters, Area bounds) {
			// each element contains an index to the writerDictionary or unassigned
			if (UsedWriters == null){
				gridDimLon = TOP_GRID_DIM_LON;
				gridDimLat = TOP_GRID_DIM_LAT;
			}
			else{
				gridDimLon = SUB_GRID_DIM_LON;
				gridDimLat = SUB_GRID_DIM_LAT;
			}
			grid = new short[gridDimLon + 1][gridDimLat + 1];
			// is true for an element if the list of writers needs to be tested
			testGrid = new boolean[gridDimLon + 1][gridDimLat + 1];
			this.bounds = bounds;
			maxCompares = fillGrid(UsedWriters);
		}
		public Area getBounds() {
			return bounds;
		}
		/**
		 * Create the grid and fill each element
		 * @param usedWriters 
		 * @param testGrid 
		 * @param grid 
		 * @return 
		 */
		private int fillGrid(BitSet usedWriters) {
			int gridStepLon, gridStepLat;
			OSMWriter[] writers = writerDictionary.getWriters();
			if (bounds == null){
				// calculate grid area
				Area tmpBounds = null;
				for (int i = 0; i<writers.length; i++){
					OSMWriter w = writers[i];
					if (usedWriters == null || usedWriters.get(i))
						tmpBounds = (tmpBounds ==null) ? w.getExtendedBounds() : tmpBounds.add(w.getExtendedBounds());
				}
				// create new Area to make sure that we don't update the writer area
				bounds = new Area(tmpBounds.getMinLat() , tmpBounds.getMinLong(), tmpBounds.getMaxLat(), tmpBounds.getMaxLong());
			}
			// save these results for later use
			gridMinLon = bounds.getMinLong();
			gridMinLat = bounds.getMinLat();
			// calculate the grid element size
			int gridWidth = bounds.getWidth();
			int gridHeight = bounds.getHeight();
			gridDivLon = Math.round((gridWidth / gridDimLon + 0.5f) );
			gridDivLat = Math.round((gridHeight / gridDimLat + 0.5f));
			gridStepLon = Math.round(((gridWidth) / gridDimLon) + 0.5f);
			gridStepLat = Math.round(((gridHeight) / gridDimLat) + 0.5f);
			assert gridStepLon * gridDimLon >= gridWidth : "gridStepLon is too small";
			assert gridStepLat * gridDimLat >= gridHeight : "gridStepLat is too small";

			int maxWriterSearch = 0;
			BitSet writerSet = new BitSet(); 
			BitSet[][] gridWriters = new BitSet[gridDimLon+1][gridDimLat+1];

			int numWriters = writerDictionary.getNumOfWriters();
			for (int j = 0; j < numWriters; j++) {
				OSMWriter w = writers[j];
				if (!(usedWriters == null || usedWriters.get(j)))
					continue;
				int minLonWriter = w.getExtendedBounds().getMinLong();
				int maxLonWriter = w.getExtendedBounds().getMaxLong();
				int minLatWriter = w.getExtendedBounds().getMinLat();
				int maxLatWriter = w.getExtendedBounds().getMaxLat();
				int startLon = Math.max(0,(minLonWriter- gridMinLon ) / gridDivLon);
				int endLon = Math.min(gridDimLon,(maxLonWriter - gridMinLon ) / gridDivLon);
				int startLat = Math.max(0,(minLatWriter- gridMinLat ) / gridDivLat);
				int endLat = Math.min(gridDimLat,(maxLatWriter - gridMinLat ) / gridDivLat);
				// add this writer to all grid elements that intersect with the writer bbox
				for (int lon = startLon; lon <= endLon; lon++) {
					int testMinLon = gridMinLon + gridStepLon * lon;
					for (int lat = startLat; lat <= endLat; lat++) {
						int testMinLat = gridMinLat + gridStepLat * lat;
						if (gridWriters[lon][lat]== null)
							gridWriters[lon][lat] = new BitSet();
						// add this writer
						gridWriters[lon][lat].set(j);
						if (!w.getExtendedBounds().contains(testMinLat, testMinLon)
								|| !w.getExtendedBounds().contains(testMinLat+ gridStepLat, testMinLon+ gridStepLon)){
							// grid area is not completely within writer area 
							testGrid[lon][lat] = true;
						}
					}
				}
			}
			for (int lon = 0; lon <= gridDimLon; lon++) {
				for (int lat = 0; lat <= gridDimLat; lat++) {
					writerSet = (gridWriters[lon][lat]);
					if (writerSet == null)
						grid[lon][lat] = AbstractMapProcessor.UNASSIGNED;
					else {
						if (testGrid[lon][lat]){
							int numTests = writerSet.cardinality();
							if (numTests  >  MAX_TESTS){ 
								if (gridStepLat > MIN_GRID_LAT && gridStepLon > MIN_GRID_LON){
									Area gridPart = new Area(gridMinLat + gridStepLat * lat, gridMinLon + gridStepLon * lon,
											gridMinLat + gridStepLat * (lat+1),
											gridMinLon + gridStepLon * (lon+1));
									// late allocation 
									if (subGrid == null)
										subGrid = new Grid [gridDimLon + 1][gridDimLat + 1];
									usedSubGridElems++;

									subGrid[lon][lat] = new Grid(writerSet, gridPart);
									numTests = subGrid[lon][lat].getMaxCompares() + 1;
									maxWriterSearch = Math.max(maxWriterSearch, numTests);
									continue;
								}
							}
							maxWriterSearch = Math.max(maxWriterSearch, numTests);
						}
						grid[lon][lat] = writerDictionary.translate(writerSet);
					}
				}
			}
			System.out.println("WriterGridTree [" + gridDimLon + "][" + gridDimLat + "] for grid area " + bounds + 
					" requires max. " + maxWriterSearch + " checks for each node (" + usedSubGridElems + " sub grid(s))" );
			return maxWriterSearch;
			
		}
		
		/**
		 * The highest number of required tests 
		 * @return
		 */
		private int getMaxCompares() {
			return maxCompares;
		}
		/**
		 * For a given node, return the list of writers that may contain it 
		 * @param node the node
		 * @return a reference to an {@link WriterGridResult} instance that contains 
		 * the list of candidates and a boolean that shows whether this list
		 * has to be verified or not. 
		 */
		public WriterGridResult get(final int lat, final int lon){
			if (!bounds.contains(lat, lon)) 
				return null;
			int gridLonIdx = (lon - gridMinLon ) / gridDivLon; 
			int gridLatIdx = (lat - gridMinLat ) / gridDivLat;

			if (subGrid != null){
				Grid sub = subGrid[gridLonIdx][gridLatIdx];
				if (sub != null){
					// get list of writer candidates from sub grid
					return sub.get(lat, lon);
				}
			}
			// get list of writer candidates from grid
			short idx = grid[gridLonIdx][gridLatIdx];
			if (idx == AbstractMapProcessor.UNASSIGNED) 
				return null;
			r.testNeeded = testGrid[gridLonIdx][gridLatIdx];
			r.l = writerDictionary.getList(idx);
			return r; 		
		}
	}
}
