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

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * Reflection utility methods for argument parsing.
 *
 * @author Chris Miller
 */
public class ReflectionUtils {
	private static final Map<Class<?>, Class<?>> boxedMappings = new HashMap<Class<?>, Class<?>>(15);

	static {
		boxedMappings.put(Boolean.TYPE, Boolean.class);
		boxedMappings.put(Byte.TYPE, Byte.class);
		boxedMappings.put(Character.TYPE, Character.class);
		boxedMappings.put(Short.TYPE, Short.class);
		boxedMappings.put(Integer.TYPE, Integer.class);
		boxedMappings.put(Long.TYPE, Long.class);
		boxedMappings.put(Float.TYPE, Float.class);
		boxedMappings.put(Double.TYPE, Double.class);
	}

	public static Class<?> getBoxedClass(Class<?> actualClass) {
		if (actualClass.isPrimitive()) {
			return boxedMappings.get(actualClass);
		}
		return actualClass;
	}

	public static boolean isBooleanReturnType(Method method) {
		Class<?> returnType = method.getReturnType();
		return returnType == Boolean.class || returnType == Boolean.TYPE;
	}

	public static boolean isEnumReturnType(Method method) {
		Class<?> returnType = method.getReturnType();
		return returnType.isEnum();
	}

	public static Option getOptionAnnotation(Method method) {
		return method.getAnnotation(Option.class);
	}

	/**
	 * Checks to make sure this is a getter with a return type.
	 * Also checks the Option annotation for the argument name.
	 *
	 * @param getter the getter method to check
	 * @return the name of the argument that corresponds to this getter.
	 */
	public static String getParamName(Method getter) {
		Class<?> returnType = getter.getReturnType();
		if (returnType == Void.TYPE) {
			throw new IllegalArgumentException("Method " + getter + " is not a getter, it doesn't return anything");
		}
		int params = getter.getParameterTypes().length;
		if (params > 0) {
			throw new IllegalArgumentException("Method " + getter + " is not a getter, it shouldn't take any parameters but takes " + params);
		}
		String name = getter.getName();
		int i = 0;
		if (name.length() > 3 && (name.startsWith("get") || name.startsWith("has") && isBooleanReturnType(getter))) {
			i = 3;
		} else if (name.length() > 2 && name.startsWith("is") && isBooleanReturnType(getter)) {
			i = 2;
		}
		if (i == 0) {
			throw new IllegalArgumentException("Method " + getter + " is not a getter, its name should begin with 'is', 'has' or 'get'");
		}
		if (getter.isAnnotationPresent(Option.class)) {
			String annotationName = getOptionAnnotation(getter).name();
			if (annotationName.length() != 0) {
				return annotationName;
			}
		}
		StringBuilder sb = new StringBuilder(name.length());
		sb.append(Character.toLowerCase(name.charAt(i)));
		for (int j = i + 1; j < name.length(); j++) {
			char ch = name.charAt(j);
			if (Character.isUpperCase(ch)) {
				sb.append('-').append(Character.toLowerCase(ch));
			} else {
				sb.append(ch);
			}
		}
		return sb.toString();
	}
}

