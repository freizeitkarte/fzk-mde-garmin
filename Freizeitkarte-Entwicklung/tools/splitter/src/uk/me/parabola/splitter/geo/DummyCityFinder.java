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

package uk.me.parabola.splitter.geo;

import java.util.Collections;
import java.util.Set;

import uk.me.parabola.splitter.Area;

/**
 * @author Chris Miller
 */
public class DummyCityFinder implements CityFinder {
	private static final Set<City> DUMMY_RESULTS = Collections.emptySet();
	@Override
	public Set<City> findCities(Area area) {
		return DUMMY_RESULTS;
	}

	@Override
	public Set<City> findCities(int minLat, int minLon, int maxLat, int maxLon) {
		return DUMMY_RESULTS;
	}
}
