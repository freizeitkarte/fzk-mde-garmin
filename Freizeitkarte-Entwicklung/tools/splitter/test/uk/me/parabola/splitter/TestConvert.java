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

import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * Unit tests for the rounding up/down utility methods.
 */
public class TestConvert {
	@Test
	public void testParseDouble() {
		parse("0");
		parse("1");
		parse("0.0000012345");
		parse("12.");
		parse(".12");
		parse("1.123");
		parse("1.123456789");
		parse("1.1234567891");
		parse("1.12345678912");
		parse("1.123456789123");
		parse("1.1234567891234");
		parse("1.12345678912345");
		parse("1.123456789123456");
		parse("1.1234567891234568");  // Note that this is in the grey area - it's at the limit of double precision
		parse("1.12345678912345678");
		parse("1.123456789012345678");
		parse("120.12345678901234567");
		parse("120.123456789012345678");
		parse("120.1234567890123456789");
		parse("120.12345678901234567892");
		parse("120.123456789012345678923");
		parse("120.1234567890123456789234");
		parse("120.12345678901234567892345");
		parse("120.123456789012345678923456");
		parse("120.1234567890123456789234567");
		parse("120.12345678901234567892345678");
		parse("120.123456789012345678923456789");
		parse("120.1234567890123456789012345678");
	}

	private void parse(String dbl) {
		Assert.assertEquals(Convert.parseDouble(dbl), Double.parseDouble(dbl), "Double parsing failed when parsing " + dbl);
	}
}