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

import org.xmlpull.v1.XmlPullParserException;

/**
 * Parses an OSM file, calling the appropriate methods on a
 * {@code MapProcessor} as it progresses.
 */
class OSMParser extends AbstractXppParser implements MapReader {


	private enum State {
		Node, Way, Relation, None
	}

	private Node currentNode = new Node();	
	private Way currentWay = new Way();	
	private Relation currentRelation = new Relation();	

	private final MapProcessor processor;
	// for status messages
	private final ElementCounter elemCounter = new ElementCounter();

	// There are mixed nodes and ways in the file
	private final boolean mixed;
	private boolean skipTags;
	private boolean skipNodes;
	private boolean skipWays;
	private boolean skipRels;

	private State state = State.None;

	OSMParser(MapProcessor processor, boolean mixed) throws XmlPullParserException {
		this.processor = processor;
		this.mixed = mixed;
		
		skipTags = processor.skipTags();
		skipNodes = processor.skipNodes();
		skipWays = processor.skipWays();
		skipRels = processor.skipRels();
	}

	/**
	 * Receive notification of the start of an element.
	 */
	@Override
	public boolean startElement(String name) {
		switch (state) {
		case None:
			CharSequence action = getAttr("action");
			if (action != null && action.equals("delete"))
				return false;
			if (name.equals("node")) {
				startNode();
			} else if (name.equals("way")) {
				if (!skipWays)
					startWay();
				else if (!mixed && skipRels)
					return true;
			} else if (name.equals("relation")) {
				if (!skipRels)
					startRelation();
				else if (!mixed)
					return true;
			} else if (name.equals("bounds") || name.equals("bound")) {
				processBounds();
			}
			break;
		case Node:
			if (!skipNodes)
				processNode(name);
			break;
		case Way:
			if (!skipWays)
				processWay(name);
			break;
		case Relation:
			if (!skipRels)
				processRelation(name);
			break;
		}
		return false;
	}

	private void startNode() {
		String idStr = getAttr("id");
		String latStr = getAttr("lat");
		String lonStr = getAttr("lon");

		if (idStr == null || latStr == null || lonStr == null) {
			// This should never happen - bad/corrupt .osm file?
			System.err.println("Node encountered with missing data. Bad/corrupt osm file? id=" + idStr + ", lat=" + latStr + ", lon=" + lonStr + ". Ignoring this node");
			return;
		}

		long id = Long.parseLong(idStr);
		double lat = Convert.parseDouble(latStr);
		double lon = Convert.parseDouble(lonStr);

		currentNode = new Node();
		currentNode.set(id, lat, lon);
		state = State.Node;
	}

	private void startWay() {
		currentWay = new Way();
		currentWay.setId(getLongAttr("id"));
		state = State.Way;
	}

	private void startRelation() {
		currentRelation = new Relation();
		currentRelation.setId(getLongAttr("id"));
		state = State.Relation;
	}

	private void processNode(CharSequence name) {
		if (name.equals("tag")) {
			if (!skipTags)
				currentNode.addTag(getAttr("k"), getAttr("v"));
		}
	}

	private void processWay(CharSequence name) {
		if (name.equals("nd")) {
			currentWay.addRef(getLongAttr("ref"));
		} else if (name.equals("tag")) {
			if (!skipTags)
				currentWay.addTag(getAttr("k"), getAttr("v"));
		}
	}

	private void processRelation(CharSequence name) {
		if (name.equals("tag")) {
			if (!skipTags)
				currentRelation.addTag(getAttr("k"), getAttr("v"));
		} else if (name.equals("member")) {
			String type = getAttr("type");
			long id = getLongAttr("ref");
			String role = getAttr("role");
			if (role == null)
				role = "";
			if ("node".equals(type))
				currentRelation.addMember("node", id, role);
			else if ("way".equals(type))
				currentRelation.addMember("way", id, role);
			else if ("relation".equals(type)) {
				currentRelation.addMember("relation", id, role);
			}
		}
	}

	private static final String[] BOUND_ATTRS = {"minlat", "minlon", "maxlat", "maxlon"};

	private void processBounds() {
		String[] split;
		String boxStr = getAttr("box");
		if (boxStr == null) {
			split = new String[4];
			for (int i = 0; i < BOUND_ATTRS.length; i++) {
				split[i] = getAttr(BOUND_ATTRS[i]);
				if (split[i] == null) {
					System.err.println("A <bounds/> tag was found but it has no 'box' attribute and no '" + BOUND_ATTRS[i] + "' attribute. Ignoring bounds");
					return;
				}
			}
		} else {
			split = boxStr.split(",");
			if (split.length != 4) {
				System.err.println(
								"A <bounds/> tag was found but its 'box' attribute contains an unexpected number of coordinates (expected 4, found " + split.length + "). Ignoring bounds");
				return;
			}
		}
		double[] coords = new double[4];
		int[] mapUnits = new int[4];
		for (int i = 0; i < 4; i++) {
			try {
				coords[i] = Double.parseDouble(split[i].trim());
			} catch (NumberFormatException e) {
				System.err.println("A <bounds/> tag was found but it contains unexpected data. Unable to parse '" + split[i] + "' as a double. Ignoring bounds");
				return;
			}
			mapUnits[i] = Utils.toMapUnit(coords[i]);
		}
		Area bounds = new Area(mapUnits[0], mapUnits[1], mapUnits[2], mapUnits[3]);

		if (bounds.getMinLong() > bounds.getMaxLong()) {
			System.out.println("A <bounds/> tag was found but it crosses +/-180 the latitude line (western edge=" +
							Utils.toDegrees(bounds.getMinLong()) + ", eastern=" + Utils.toDegrees(bounds.getMaxLong()) +
							"). The splitter isn't currently able to deal with this, so the bounds are being ignored");
			return;
		}

		processor.boundTag(bounds);
		System.out.println("A <bounds/> tag was found. Area covered is " + bounds.toString());
	}

	/**
	 * Receive notification of the end of an element.
	 */
	@Override
	public void endElement(String name) {
		if (state == State.Node) {
			if (name.equals("node")) {
				if (!skipNodes)
					processor.processNode(currentNode);
				state = State.None;
				elemCounter.countNode(currentNode.getId());
			}
		} else if (state == State.Way) {
			if (name.equals("way")) {
				if (!skipWays)
					processor.processWay(currentWay);
				state = State.None;
				elemCounter.countWay(currentWay.getId());
			}
		} else if (state == State.Relation) {
			if (name.equals("relation")) {
				if (!skipRels)
					processor.processRelation(currentRelation);
				state = State.None;
				elemCounter.countRelation(currentRelation.getId());
			}
		}
	}
}