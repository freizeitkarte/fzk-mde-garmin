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

public interface MapProcessor {

	/**
	 * (performance) Returns true if the reader is allowed to ignore tags
	 * while reading OSM data
	 */
	
	boolean skipTags();
	/**
	 * (performance) Returns true if the reader is allowed to skip nodes
	 * while reading OSM data
	 */
	boolean skipNodes();

	/**
	 * (performance) Returns true if the reader is allowed to skip ways 
	 * while reading OSM data
	 */
	boolean skipWays();
	/**
	 * (performance) Returns true if the reader is allowed to skip relations
	 * while reading OSM data
	 */
	boolean skipRels();

	/**
	 * returns a value that identifies the current phase
	 * @return
	 */
	int getPhase();

	/**
	 * Called when the bound tag is encountered. Note that it is possible
	 * for this to be called multiple times, eg if there are multiple OSM
	 * files provided as input.
	 * @param bounds the area covered by the map.
	 */
	void boundTag(Area bounds);


	/**
	 * Called when a whole node has been processed. 
	*/
	void processNode(Node n);

	/**
	 * Called when a whole way has been processed. 
	*/
	void processWay(Way w);
	
	/**
	 * Called when a whole relation has been processed. 
	*/
	void processRelation(Relation r);


	/**
	 * Called when all input files were processed,
	 * it returns false to signal that the same instance of the processor
	 * should be called again with a new reader for all these input files.
	 */
	boolean endMap();
}
