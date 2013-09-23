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

import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import uk.me.parabola.splitter.Area;

/**
 * Manages a store of city details in a format optimised for fast
 * retrieval based on lat/lon coordinates.
 *
 * @author Chris Miller
 */
public class DefaultCityFinder implements CityFinder {
	private final int[] lats;
	private final int[] lons;
	private final City[] citiesByLat;

	/**
	 * Creates a city store that holds all the given cities.
	 */
	public DefaultCityFinder(List<City> cities) {

		lats = new int[cities.size()];
		lons = new int[cities.size()];
		citiesByLat = new City[cities.size()];

		Collections.sort(cities, new Comparator<City>() {
			@Override
			public int compare(City c1, City c2) {
				return c1.getLat() < c2.getLat() ? -1 : c1.getLat() == c2.getLat() ? 0 : 1;
			}
		});
		int i = 0;
		for (City city : cities) {
			lats[i] = city.getLat();
			lons[i] = city.getLon();
			citiesByLat[i++] = city;
		}
	}

	/**
	 * Retrieves all the cities that fall within the given bounds.
	 */
	@Override
	public Set<City> findCities(Area area) {
		return findCities(area.getMinLat(), area.getMinLong(), area.getMaxLat(), area.getMaxLong());
	}

	/**
	 * Retrieves all the cities that fall within the given bounds.
	 */
	@Override
	public Set<City> findCities(int minLat, int minLon, int maxLat, int maxLon) {

		int minLatIndex = findMinIndex(lats, minLat);
		int maxLatIndex = findMaxIndex(lats, maxLat);

		if (minLatIndex > maxLatIndex)
			return Collections.emptySet();

		Set<City> hits = new HashSet<City>(100);

		for (int i = minLatIndex; i <= maxLatIndex; i++) {
			City city = citiesByLat[i];
			if (city.getLon() >= minLon && city.getLon() <= maxLon)
				hits.add(city);
		}
		return hits;
	}

	private static int findMinIndex(int[] data, int value) {
		int result = Arrays.binarySearch(data, value);
		if (result < 0)
			return -1 - result;
		while (result > 0 && data[result - 1] == value)
			result--;
		return result;
	}

	private static int findMaxIndex(int[] data, int value) {
		int result = Arrays.binarySearch(data, value);
		if (result < 0)
			return -2 - result;
		while (result < data.length - 2 && data[result + 1] == value)
			result++;
		return result;
	}
}
