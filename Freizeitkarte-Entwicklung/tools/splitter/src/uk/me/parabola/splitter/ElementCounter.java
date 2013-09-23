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
 * Common OSM reader method for status messages
 * @author GerdP
 *
 */
public class ElementCounter {
	// How many elements to process before displaying a status update
	private static final int NODE_STATUS_UPDATE_THRESHOLD = 10000000;
	private static final int WAY_STATUS_UPDATE_THRESHOLD = 1000000;
	private static final int RELATION_STATUS_UPDATE_THRESHOLD = 100000;
	
	// for messages
	private long nodeCount;
	private long wayCount;
	private long relationCount;

	/**
	 * Count node and eventually print progress message with the node id
	 * @param id
	 */
	protected void countNode(long id) {
		nodeCount++;
		if (nodeCount % NODE_STATUS_UPDATE_THRESHOLD == 0) {
			System.out.println(Utils.format(nodeCount) + " nodes processed... id=" + id);
		}

	}

	/**
	 * Count way and eventually print progress message with the way id
	 * @param id
	 */
	protected void countWay(long id)  {
		wayCount++;
		if (wayCount % WAY_STATUS_UPDATE_THRESHOLD == 0) {
			System.out.println(Utils.format(wayCount) + " ways processed... id=" + id);
		}
	}

	/**
	 * Count relation and eventually print progress message with the relation id
	 * @param id
	 */
	protected void countRelation(long id)  {
		relationCount++;
		if (relationCount % RELATION_STATUS_UPDATE_THRESHOLD == 0) {
			System.out.println(Utils.format(relationCount) + " relations processed... id=" + id);
		}
	}
	
}
