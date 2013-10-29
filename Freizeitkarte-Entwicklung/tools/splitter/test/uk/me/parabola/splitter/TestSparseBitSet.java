/*
 * Copyright (C) 2012.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 or
 * version 2 as published by the Free Software Foundation.
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
 * Unit tests for the sparse BitSet implementaion
 */
public class TestSparseBitSet{
         private final int NUM = 10000;
         private final long[] POS = {1, 63, 64, 65, 4711, 12345654321L};
	@Test
	public void testSparseBitSetSequential() {
         SparseBitSet sparseSet = new SparseBitSet();
         for (long i = 1; i < NUM; i++){
             Assert.assertEquals(sparseSet.get(i), false, "get("+i+")"); 
         }
         for (long i = 1; i < NUM; i++){
             sparseSet.set(i);
             Assert.assertEquals(sparseSet.get(i), true, "get("+i+")"); 
         }
         Assert.assertEquals(sparseSet.cardinality(), NUM-1, "cardinality() returns wrong value");
         for (long i = 1; i < NUM; i++){
             sparseSet.clear(i);
             Assert.assertEquals(sparseSet.get(i), false, "get("+i+")"); 
             Assert.assertEquals(sparseSet.cardinality(), NUM-i-1, "cardinality() returns wrong value");
         }
         
  }
	@Test
  public void testSparseBitSetRandom() {
         SparseBitSet sparseSet = new SparseBitSet();
         for (long i: POS){
             sparseSet.set(i);
             Assert.assertEquals(sparseSet.get(i), true, "get("+i+")"); 
             Assert.assertEquals(sparseSet.cardinality(), 1, "cardinality() returns wrong value");
             sparseSet.clear(i);
             Assert.assertEquals(sparseSet.get(i), false, "get("+i+")"); 
             Assert.assertEquals(sparseSet.cardinality(), 0, "cardinality() returns wrong value");
         }
         
  }
}