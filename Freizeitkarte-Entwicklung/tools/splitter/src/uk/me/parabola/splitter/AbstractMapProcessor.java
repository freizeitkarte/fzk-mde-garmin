/*
 * Copyright (c) 2012.
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

public abstract class AbstractMapProcessor implements MapProcessor {
	public static final short UNASSIGNED = Short.MIN_VALUE;

	public boolean isStartNodeOnly(){
		return false;
	}
	public boolean skipTags(){
		return false;
	}
	public boolean skipNodes(){
		return false;
	}
	public boolean skipWays(){
		return false;
	}
	public boolean skipRels(){
		return false;
	}

	public void boundTag(Area bounds){}

	public void processNode(Node n){}

	public void processWay(Way w){}
	
	public void processRelation(Relation r) {}

	public boolean endMap(){
		return true;
	}
	public int getPhase() {
		return 1;
	}
}
