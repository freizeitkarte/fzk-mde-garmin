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

import java.util.Set;

import uk.me.parabola.splitter.Area;

public interface CityFinder {
	Set<City> findCities(Area area);

	Set<City> findCities(int minLat, int minLon, int maxLat, int maxLon);
}
