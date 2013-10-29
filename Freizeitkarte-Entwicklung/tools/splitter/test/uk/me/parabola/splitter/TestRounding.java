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
public class TestRounding {
	@Test
	public void testPositiveRoundingDown() {
		for (int i = 0; i < 50000; i += 19) {
			testRoundDown(i, 11, i / 2048 * 2048);
		}
		testRoundDown(0x1d5842, 11, 0x1d5800);
		testRoundDown(0x2399a, 11, 0x23800);
		testRoundDown(0x23800, 11, 0x23800);
		testRoundDown(0x237f0, 11, 0x23000);
	}

	@Test
	public void testPositiveRoundingUp() {
		for (int i = 0; i < 50000; i += 19) {
			testRoundUp(i, 11, (i + 2047) / 2048 * 2048);
		}
		testRoundUp(0x1e7faa, 11, 0x1e8000);
		testRoundUp(0x1e7801, 11, 0x1e8000);
		testRoundUp(0x1e7800, 11, 0x1e7800);
		testRoundUp(0x1e70aa, 11, 0x1e7800);
		testRoundUp(0x1e77ff, 11, 0x1e7800);
	}

	@Test
	public void testNegativeRoundingDown() {
		testRoundDown(0xffcbba86, 11, 0xffcbb800);
		testRoundDown(0xffcbbfff, 11, 0xffcbb800);
		testRoundDown(0xffcbb801, 11, 0xffcbb800);
		testRoundDown(0xffcbb7ff, 11, 0xffcbb000);
	}

	@Test
	public void testNegativeRoundingUp() {
		testRoundUp(0xffcbba86, 11, 0xffcbc000);
		testRoundUp(0xffcbbfff, 11, 0xffcbc000);
		testRoundUp(0xffcbb801, 11, 0xffcbc000);
		testRoundUp(0xffcbb7ff, 11, 0xffcbb800);
		testRoundUp(Integer.MIN_VALUE + 1234, 11, 0x80000800);
	}

	@Test
	public void testRound() {
		testRound(7, 2, 8);
		testRound(6, 2, 8);
		testRound(5, 2, 4);
		testRound(4, 2, 4);
		testRound(3, 2, 4);
		testRound(2, 2, 4);
		testRound(1, 2, 0);
		testRound(0, 2, 0);
		testRound(-1, 2, 0);
		testRound(-2, 2, 0);
		testRound(-3, 2, -4);
		testRound(-4, 2, -4);
		testRound(-5, 2, -4);
	}

	private void testRoundDown(int value, int shift, int outcome) {
		Assert.assertEquals(RoundingUtils.roundDown(value, shift), outcome, "Before: " + Integer.toHexString(value) +
						", After: " + Integer.toHexString(RoundingUtils.roundDown(value, shift)));
	}

	private void testRoundUp(int value, int shift, int outcome) {
		Assert.assertEquals(RoundingUtils.roundUp(value, shift), outcome, "Before: " + Integer.toHexString(value) +
						", After: " + Integer.toHexString(RoundingUtils.roundUp(value, shift)));
	}

	private void testRound(int value, int shift, int outcome) {
		Assert.assertEquals(RoundingUtils.round(value, shift), outcome, "Before: " + Integer.toHexString(value) +
						", After: " + Integer.toHexString(RoundingUtils.round(value, shift)));
	}
}