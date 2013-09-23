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

import java.io.File;
import java.util.HashMap;
import java.util.Map;

/**
 * Converts arguments from a String to another type.
 *
 * @author Chris Miller
 */
public class ParamConverter {
	private final Map<Class<?>, Converter<?>> converterMap;
	private final Map<Class<?>, Object> primitiveDefaults;

	public ParamConverter() {
		converterMap = new HashMap<Class<?>, Converter<?>>(10);
		converterMap.put(String.class, new Converter<String>() { @Override String convert(String value) { return value; } });
		converterMap.put(Boolean.class, new Converter<Boolean>() { @Override Boolean convert(String value) { return Boolean.valueOf(value); } });
		converterMap.put(Integer.class, new IntegerConverter());
		converterMap.put(Long.class, new LongConverter());
		converterMap.put(File.class, new Converter<File>() { @Override File convert(String value) { return new File(value); } });
		converterMap.put(ThreadCount.class, new ThreadCountConverter());

		primitiveDefaults = new HashMap<Class<?>, Object>(10);
		primitiveDefaults.put(Boolean.TYPE, Boolean.FALSE);
		primitiveDefaults.put(Byte.TYPE, Byte.valueOf((byte) 0));
		primitiveDefaults.put(Character.TYPE, Character.valueOf('\u0000'));
		primitiveDefaults.put(Short.TYPE, Short.valueOf((short) 0));
		primitiveDefaults.put(Integer.TYPE, Integer.valueOf(0));
		primitiveDefaults.put(Long.TYPE, Long.valueOf(0));
		primitiveDefaults.put(Float.TYPE, Float.valueOf(0.0f));
		primitiveDefaults.put(Double.TYPE, Double.valueOf(0.0d));
	}

	public Object getPrimitiveDefault(Class<?> returnType) {
		return primitiveDefaults.get(returnType);
	}

	/**
	 * Convert the argument to the target type
	 *
	 * @param param the parameter being converted.
	 * @param value the value to convert.
	 * @return the converted argument.
	 * @throws Exception if the string could not be converted.
	 */
	public Object convert(Param param, String value) {
		if (value == null)
			return param.getDefaultValue();
		Converter<?> converter = converterMap.get(param.getReturnType());
		if (converter == null)
			throw new UnsupportedOperationException("Unable to convert parameters of type " + param.getReturnType() + ". Parameter " + param.getName() + " (value=" + value + ") could not be converted.");
		return converter.convert(value);
	}

	private abstract static class Converter<T> {
		abstract T convert(String value);
	}

	private static class IntegerConverter extends Converter<Integer> {
		@Override Integer convert(String value) {
			try {
				return Integer.valueOf(value);
			} catch (NumberFormatException e) {
				throw new NumberFormatException('\'' + value + "' is not a valid number.");
			}
		}
	}

	private static class LongConverter extends Converter<Long> {
		@Override Long convert(String value) {
			try {
				return Long.valueOf(value);
			} catch (NumberFormatException e) {
				throw new NumberFormatException('\'' + value + "' is not a valid number.");
			}
		}
	}

	private static class ThreadCountConverter extends Converter<ThreadCount> {
		@Override
		ThreadCount convert(String value) {
			int cpuCores = Runtime.getRuntime().availableProcessors();
			if ("auto".equals(value)) {
				return new ThreadCount(cpuCores, true);
			} else {
				int threads = 0;
				boolean valid = false;
				try {
					threads = Integer.valueOf(value);
					if (threads >= 1) {
						valid = true;
					}
				} catch (NumberFormatException e) {
				}
				if (!valid) {
					throw new IllegalArgumentException(
							'\'' + value + "' should be a number >= 1, or 'auto' to use all available CPU cores.");
				}
				return new ThreadCount(threads, false);
			}
		}
	}
}
