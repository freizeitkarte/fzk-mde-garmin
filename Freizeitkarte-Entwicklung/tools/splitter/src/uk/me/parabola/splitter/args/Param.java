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
 * A single command line parameter.
 *
 * @author Chris Miller
 */
public class Param {
	private final String name;
	private final String description;
	private final String defaultValue;
	private final Class<?> returnType;

	public Param(String name, String description, String defaultValue, Class<?> returnType) {
		this.name = name;
		this.description = description;
		this.defaultValue = defaultValue;
		this.returnType = returnType;
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}

	public String getDefaultValue() {
		return defaultValue;
	}

	public Class<?> getReturnType() {
		return returnType;
	}
}
