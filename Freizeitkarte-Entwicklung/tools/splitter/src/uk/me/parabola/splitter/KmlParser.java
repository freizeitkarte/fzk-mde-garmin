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

import java.util.ArrayList;
import java.util.List;

import org.xmlpull.v1.XmlPullParserException;

/**
 * Parses a KML area file.
 *
 * @author Chris Miller
 */
public class KmlParser extends AbstractXppParser {

	private enum State { None, Placemark, Name, Polygon, OuterBoundaryIs, LinearRing, Coordinates }

	private State state = State.None;
	private int currentId;
	private int[] currentCoords = new int[10];
	private List<Area> areas = new ArrayList<Area>();

	public KmlParser() throws XmlPullParserException {
	}

	public List<Area> getAreas() {
		return areas;
	}

	@Override
	protected boolean startElement(String name) throws XmlPullParserException {
		switch (state) {
		case None:
			if (name.equals("Placemark"))
				state = State.Placemark;
			break;
		case Placemark:
			if (name.equals("name")) {
				state = State.Name;
			} else if (name.equals("Polygon")) {
				state = State.Polygon;
			}
			break;
		case Polygon:
			if (name.equals("outerBoundaryIs")) {
				state = State.OuterBoundaryIs;
			}
			break;
		case OuterBoundaryIs:
			if (name.equals("LinearRing")) {
				state = State.LinearRing;
			}
			break;
		case LinearRing:
			if (name.equals("coordinates")) {
				state = State.Coordinates;
			}
			break;
		default:
		}
		return false;
	}

	@Override
	protected void text() throws XmlPullParserException {
		if (state == State.Name) {
			String idStr = getTextContent();
			try {
				currentId = Integer.valueOf(idStr);
			} catch (NumberFormatException e) {
				throw createException("Unexpected area name encountered. Expected a valid number, found \"" + idStr + '"');
			}
		} else if (state == State.Coordinates) {
			String coordText = getTextContent();
			String[] coordPairs = coordText.trim().split("\\s+");
			if (coordPairs.length != 5) {
				throw createException("Unexpected number of coordinates. Expected 5, found " + coordPairs.length + " in \"" + coordText + '"');
			}
			for (int i = 0; i < 5; i++) {
				String[] coordStrs = coordPairs[i].split(",");
				if (coordStrs.length != 2) {
					throw createException(
									"Unexpected coordinate pair encountered in \"" + coordPairs[i] + "\". Expected 2 numbers, found " + coordStrs.length);
				}
				for (int j = 0; j < 2; j++) {
					try {
						Double val = Double.valueOf(coordStrs[j]);
						currentCoords[i * 2 + j] = Utils.toMapUnit(val);
					} catch (NumberFormatException e) {
						throw createException("Unexpected coordinate encountered. \"" + coordStrs[j] + "\" is not a valid number");
					}
				}
			}
		}
	}

	@Override
	protected void endElement(String name) throws XmlPullParserException {
		if (state == State.Name) {
			state = State.Placemark;
		} else if (state == State.Coordinates) {
			state = State.LinearRing;
		} else if (name.equals("Placemark")) {
			int minLat = currentCoords[1];
			int minLon = currentCoords[0];
			int maxLat = currentCoords[5];
			int maxLon = currentCoords[4];
			Area a = new Area(minLat, minLon, maxLat, maxLon);
			a.setMapId(currentId);
			areas.add(a);
			state = State.None;
		}
	}
}
