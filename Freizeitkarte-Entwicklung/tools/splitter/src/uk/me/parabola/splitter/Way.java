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

import it.unimi.dsi.fastutil.longs.LongArrayList;

/**
 * @author Steve Ratcliffe
 */
public class Way extends Element {
	private final LongArrayList refs = new LongArrayList(10);

	public void set(long id){
		setId(id);
	}
	
	public void addRef(long ref) {
		refs.add(ref);
	}

	public LongArrayList getRefs() {
		return refs;
	}
}
