/*
 * Copyright (C) 2011 by the splitter contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
package uk.me.parabola.splitter;

/**
 * Thrown when an unknown feature is required to process one of the input files.
 *
 * @author Steve Ratcliffe
 */
public class UnknownFeatureException extends RuntimeException {
	public UnknownFeatureException(String s) {
		super(s);
	}
}
