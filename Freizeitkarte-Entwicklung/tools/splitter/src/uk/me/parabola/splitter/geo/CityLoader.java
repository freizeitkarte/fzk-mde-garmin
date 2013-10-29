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

import java.io.BufferedReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import uk.me.parabola.splitter.Convert;
import uk.me.parabola.splitter.Utils;

/**
 * Loads in city information from a GeoNames file. See
 * http://download.geonames.org/export/dump/readme.txt for details of the file format.
 *
 * @author Chris Miller
 */
public class CityLoader {
	private static final Pattern TAB_DELIMTED_SPLIT_PATTERN = Pattern.compile("\\t");

	private static final int GEONAME_ID_INDEX = 0;
	private static final int NAME_INDEX = 1;
	private static final int ASCII_NAME_INDEX = 2;
	private static final int COUNTRY_CODE_INDEX = 8;
	private static final int LAT_INDEX = 4;
	private static final int LON_INDEX = 5;
	private static final int POPULATION_INDEX = 14;

	private final boolean useAsciiNames;

	public CityLoader(boolean useAsciiNames) {
		this.useAsciiNames = useAsciiNames;
	}

	public List<City> load(String geoNamesFile) throws IOException {
		BufferedReader r = new BufferedReader(Utils.openFile(geoNamesFile, true));
		List<City> result;
		try {
			result = load(r);
		}
		finally {
			try {
				r.close();
			} catch (IOException ignore) {
			}
		}
		return result;
	}

	public List<City> load(BufferedReader reader) throws IOException {
		List<City> cities = new ArrayList<City>(1000);
		String line;
		int lineNumber = 0;
		while ((line = reader.readLine()) != null) {
			lineNumber++;
			try {
				String[] split = TAB_DELIMTED_SPLIT_PATTERN.split(line, 16);
				int geoNameId = Integer.parseInt(split[GEONAME_ID_INDEX]);
				String name;
				if (useAsciiNames)
					name = new String(split[ASCII_NAME_INDEX].toCharArray()); // prevent memory leak from substr
				else
					name = new String(split[NAME_INDEX].toCharArray());
				String countryCode = new String(split[COUNTRY_CODE_INDEX].toCharArray()).intern();
				int population = Integer.parseInt(split[POPULATION_INDEX]);
				int lat = Utils.toMapUnit(Convert.parseDouble(split[LAT_INDEX]));
				int lon = Utils.toMapUnit(Convert.parseDouble(split[LON_INDEX]));

				cities.add(new City(geoNameId, countryCode, name, lat, lon, population));
			} catch (Exception e) {
				System.err.format("Unable to parse GeoNames data at line %d%nReason:%s%nData: %s%n",lineNumber,  e.toString(),line);
			}
		}
		return cities;
	}
}
