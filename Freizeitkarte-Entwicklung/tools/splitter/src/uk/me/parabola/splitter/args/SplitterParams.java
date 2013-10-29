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

package uk.me.parabola.splitter.args;

/**
 * Command line parameters for the splitter
 *
 * @author Chris Miller
 */
public interface SplitterParams {
	/**
	 * @return the ID for the first split area.
	 */
	@Option(defaultValue = "63240001", description = "The starting map ID.")
	int getMapid();

	@Option(description = "A default description to give to each area.")
	String getDescription();

	@Option(defaultValue = "512", description = "The maximum number of areas to process in a single pass. More areas require more memory, but less time. Values: 1-4096.")
	int getMaxAreas();

	@Option(defaultValue = "auto", description = "Deprecated. Nodes/ways/rels that fall outside an area will still " 
			+ "be included if they are within this many map units. ")
	String getOverlap();

	@Option(defaultValue = "1600000", description = "A threshold value that is used when no split-file is given. Splitting is done so that "
			+ "no tile has more than maxNodes nodes inside the bounding box of the tile. "
			+ "Nodes added by overlap or keep-complete are not taken into account.")
	int getMaxNodes();

	@Option(defaultValue = "13", description = "The resolution of the overview map to be produced by mkgmap.")
	int getResolution();

	@Option(description = "Specify this if the input osm file has nodes, ways and relations intermingled.")
	boolean isMixed();

	@Option(description = "Deprecated, now does nothing")
	String getCache();

	@Option(description = "The path to the output directory. Defaults to the current working directory.")
	String getOutputDir();

	@Option(description = "The name of a file containing the areas definitions. Can be .list or .kml. Providing such a file will save processing time.")
	String getSplitFile();

	@Option(description = "The name of a GeoNames file to use for determining tile names. Typically cities15000.zip from http://download.geonames.org/export/dump/")
	String getGeonamesFile();

	@Option(description = "The name of a kml file to write out the areas to. This is in addition to areas.list (which is always written out).")
	String getWriteKml();

	@Option(defaultValue = "120", description = "Displays the amount of memory used by the JVM every --status-freq seconds. Set =0 to disable.")
	int getStatusFreq();

	@Option(description = "Don't trim empty space off the edges of tiles.")
	boolean isNoTrim();

	@Option(defaultValue = "auto", description = "The maximum number of threads used by splitter.")
	ThreadCount getMaxThreads();
	
	@Option(defaultValue = "pbf", description = "The output type, either pbf, o5m, or xml.")
	String getOutput();

	@Option(description = "The name of a file containing ways and relations that are known to cause problems in the split process.")
	String getProblemFile();

	@Option(defaultValue="true", description = "Write complete ways and relations if possible (requires more time and more heap memory). This should be used "
			+ "with --overlap=0")
	boolean isKeepComplete();

//	@Option(description = "Just write program version and build timestamp")
//	boolean getVersion();

	@Option(description = "The name of a file to write the generated problem list created with --keep-complete.")
	String getProblemReport();

	@Option(description = "The name of a file containing a bounding polygon in osmosis polygon file format.")
	String getPolygonFile();

	@Option(defaultValue = "dist", description = "Debugging: stop after the program phase. Can be split, gen-problem-list, or handle-problem-list")
	String getStopAfter();
	
	@Option(description = "The name of a directory containing precompiled sea tiles.")
	String getPrecompSea();

	@Option(defaultValue="use-exclude-list", description = "A comma separated list of tag values for relations. " 
			+ "Used to filter multipolygon and boundary relations for problem-list processing.")
	String getBoundaryTags();

}
