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

import java.awt.Point;
import java.awt.Polygon;
import java.awt.Rectangle;
import java.awt.geom.Path2D;
import java.awt.geom.PathIterator;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.Charset;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.GZIPInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.apache.tools.bzip2.CBZip2InputStream;


/**
 * Some miscellaneous functions that are used within the .img code.
 *
 * @author Steve Ratcliffe
 */
public class Utils {

	private static final NumberFormat FORMATTER = NumberFormat.getIntegerInstance();

	public static String format(int number) {
		return FORMATTER.format(number);
	}

	public static String format(long number) {
		return FORMATTER.format(number);
	}

	public static double toDegrees(int val) {
		return (double) val / ((1 << 24) / 360.0);
	}

	/**
	 * A map unit is an integer value that is 1/(2^24) degrees of latitude or
	 * longitude.
	 *
	 * @param l The lat or long as decimal degrees.
	 * @return An integer value in map units.
	 */
	public static int toMapUnit(double l) {
		double DELTA = 0.000001; // TODO check if we really mean this
		if (l > 0)
			return (int) ((l + DELTA) * (1 << 24)/360);
		else
			return (int) ((l - DELTA) * (1 << 24)/360);
	}
	
	/**
	 * Open a file and apply filters necessary to reading it such as decompression.
	 *
	 * @param name The file to open. gz, zip, bz2 are supported.
	 * @return A stream that will read the file, positioned at the beginning.
	 * @throws IOException If the file cannot be opened for any reason.
	 */
	@SuppressWarnings("resource")
	public static Reader openFile(String name, boolean backgroundReader) throws IOException {
		InputStream is = new BufferedInputStream(new FileInputStream(name), 8192);
		if (name.endsWith(".gz")) {
			try {
				is = new GZIPInputStream(is);
			} catch (IOException e) {
				throw new IOException( "Could not read " + name + " as a gz compressed file", e);
			}
		} else if (name.endsWith(".bz2")) {
			try {
				is.read(); is.read();
				is = new CBZip2InputStream(is);
			} catch (IOException e) {
				throw new IOException( "Could not read " + name + " as a bz2 compressed file", e);
			}
		} else if (name.endsWith(".zip")) {
			ZipInputStream zis = new ZipInputStream(is);
			name = new File(name).getName();  // Strip off any path
			ZipEntry entry;
			while ((entry = zis.getNextEntry()) != null) {
				if (entry.getName().startsWith(name.substring(0, name.length() - 4))) {
					is = zis;
					break;
				}
			}
			if (is != zis) {
				zis.close();
				throw new IOException("Unable to find a file inside " + name + " that starts with " + name.substring(0, name.length() - 4));
			}
		}
		if (backgroundReader) {
			is = new BackgroundInputStream(is);
		}
		return new InputStreamReader(is, Charset.forName("UTF-8"));
	}
	
	public static Rectangle area2Rectangle (Area area, int overlap){
		return new Rectangle(area.getMinLong()-overlap, area.getMinLat()-overlap,area.getWidth()+2*overlap,area.getHeight()+2*overlap);
	}
	/**
	 * Convert area into a list of polygons each represented by a list
	 * of points. It is possible that the area contains multiple discontinuous
	 * polygons, so you may append more than one shape to the output list.<br/>
	 * <b>Attention:</b> The outline of the polygon has clockwise order whereas
	 * holes in the polygon have counterclockwise order. 
	 * 
	 * Taken from Java2DConverter by WanMil in mkgmap
	 * @param area The area to be converted.
	 * @return a list of closed polygons
	 */
	public static List<List<Point>> areaToShapes(java.awt.geom.Area area) {
		List<List<Point>> outputs = new ArrayList<List<Point>>(4);

		float[] res = new float[6];
		PathIterator pit = area.getPathIterator(null);
		
		List<Point> points = null;

		int iPrevLat = Integer.MIN_VALUE;
		int iPrevLong = Integer.MIN_VALUE;

		while (!pit.isDone()) {
			int type = pit.currentSegment(res);

			float fLat = res[1];
			float fLon = res[0];
			int iLat = Math.round(fLat);
			int iLon = Math.round(fLon);
			
			switch (type) {
			case PathIterator.SEG_LINETO:

				if (iPrevLat != iLat || iPrevLong != iLon) 
					points.add(new Point(iLon,iLat));

				iPrevLat = iLat;
				iPrevLong = iLon;
				break;
			case PathIterator.SEG_MOVETO: 
			case PathIterator.SEG_CLOSE:
				if ((type == PathIterator.SEG_MOVETO && points != null) || type == PathIterator.SEG_CLOSE) {
					if (points.size() > 2 && points.get(0).equals(points.get(points.size() - 1)) == false) {
						points.add(points.get(0));
					}
					if (points.size() > 3){
						outputs.add(points);
					}
				}
				if (type == PathIterator.SEG_MOVETO){
					points = new ArrayList<Point>();
					points.add(new Point(iLon,iLat));
					iPrevLat = iLat;
					iPrevLong = iLon;
				} else {
					points = null;
					iPrevLat = Integer.MIN_VALUE;
					iPrevLong = Integer.MIN_VALUE;
				}
				break;
			default:
				System.out.println("Unsupported path iterator type " + type
						+ ". This is an mkgmap error.");
			}

			pit.next();
		}

		return outputs;
	}

	/**
	 * Convert list of points which describe a closed polygon to an area
	 * Taken from Java2DConverter by WanMil in mkgmap
	 * @param shape
	 * @return
	 */
	public static java.awt.geom.Area shapeToArea(List<Point> shape){
		Polygon polygon = new Polygon();
		for (Point point : shape) {
			polygon.addPoint(point.x, point.y);
		}
		return new java.awt.geom.Area(polygon);
	}
	
	/**
	 * Convert area with coordinates in degrees to area in MapUnits
	 * @param area
	 * @return
	 */
	public static java.awt.geom.Area AreaDegreesToMapUnit(java.awt.geom.Area area){
		if (area == null)
			return null;
		double[] res = new double[6];
		Path2D path = new Path2D.Double();
		PathIterator pit = area.getPathIterator(null);
		while (!pit.isDone()) {
			int type = pit.currentSegment(res);

			double fLat = res[1];
			double fLon = res[0];
			int lat = toMapUnit(fLat);
			int lon = toMapUnit(fLon);
			
			switch (type) {
			case PathIterator.SEG_LINETO:
				path.lineTo(lon, lat);
				break;
			case PathIterator.SEG_MOVETO: 
				path.moveTo(lon, lat);
				break;
			case PathIterator.SEG_CLOSE:
				path.closePath();
				break;
			default:
				System.out.println("Unsupported path iterator type " + type
						+ ". This is an mkgmap error.");
			}

			pit.next();
		}
		return new java.awt.geom.Area(path);
	}
	
	// returns true if the way is a closed polygon with a clockwise
	// direction
	public static boolean clockwise(List<Point> points) {

		if(points.size() < 3 || !points.get(0).equals(points.get(points.size() - 1)))
			return false;

		long area = 0;
		Point p1 = points.get(0);
		for(int i = 1; i < points.size(); ++i) {
			Point p2 = points.get(i);
			area += ((long)p1.x * p2.y- 
					 (long)p2.x * p1.y);
			p1 = p2;
		}

		// this test looks to be inverted but gives the expected result!
		// empty linear areas are defined as clockwise 
		return area <= 0;
	}


	public static void printMem(){
		long maxMem = Runtime.getRuntime().maxMemory() / 1024 / 1024;
		long totalMem = Runtime.getRuntime().totalMemory() / 1024 / 1024;
		long freeMem = Runtime.getRuntime().freeMemory() / 1024 / 1024;
		long usedMem = totalMem - freeMem;
		System.out.println("  JVM Memory Info: Current " + totalMem + "MB (" + usedMem + "MB used, " + freeMem + "MB free) Max " + maxMem + "MB");

	}
}

