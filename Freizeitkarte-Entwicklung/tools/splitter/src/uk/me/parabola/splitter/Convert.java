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

/**
 * Conversion utility methods
 *
 * @author Chris Miller
 */
public class Convert {
	private static final double[] PowersOfTen = new double[] {
					10d,
					100d,
					1000d,
					10000d,
					100000d,
					1000000d,
					10000000d,
					100000000d,
					1000000000d,
					10000000000d,
					100000000000d,
					1000000000000d,
					10000000000000d,
					100000000000000d,
					1000000000000000d,
					10000000000000000d,
					100000000000000000d,
					1000000000000000000d,
					10000000000000000000d,
	};

	/**
	 * Parses a string into a double. This code is optimised for performance
	 * when parsing typical doubles encountered in .osm files.
	 *
	 * @param cs the characters to parse into a double
	 * @return the double value represented by the string.
	 * @throws NumberFormatException if the value failed to parse.
	 */
	public static double parseDouble(String cs) throws NumberFormatException
	{
		int end = Math.min(cs.length(), 19);  // No point trying to handle more digits than a double precision number can deal with
		int i = 0;
		char c = cs.charAt(i);

		boolean isNegative = (c == '-');
		if ((isNegative || (c == '+')) && (++i < end))
			c = cs.charAt(i);

		long decimal = 0;
		int decimalPoint = -1;
		while (true) {
			int digit = c - '0';
			if ((digit >= 0) && (digit < 10)) {
				long tmp = decimal * 10 + digit;
				if (tmp < decimal)
					throw new NumberFormatException("Overflow! Too many digits in " + cs);
				decimal = tmp;
			} else if ((c == '.') && (decimalPoint < 0))
				decimalPoint = i;
			else {
				// We're out of our depth, let the JDK have a go. This is *much* slower
				return Double.parseDouble(cs);
			}
			if (++i >= end)
				break;
			c = cs.charAt(i);
		}
		if (isNegative)
			decimal = -decimal;

               if (decimalPoint >= 0 && decimalPoint < i - 1)
			return decimal / PowersOfTen[i - decimalPoint - 2];
		else
			return decimal;
	}
}
