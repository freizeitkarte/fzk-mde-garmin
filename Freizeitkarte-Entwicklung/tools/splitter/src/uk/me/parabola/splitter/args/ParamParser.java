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

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import uk.me.parabola.splitter.Version;

/**
 * Parses command line arguments and returns them via the supplied interface.
 *
 * @author Chris Miller
 */
public class ParamParser {

	private final ParamConverter converter = new ParamConverter();
	private final Map<String, Param> paramMap = new TreeMap<String, Param>();
	private final Map<String, Object> convertedParamMap = new TreeMap<String, Object>();
	private final List<String> additionalParams = new ArrayList<String>();
	private final List<String> errors = new ArrayList<String>();
	private boolean wantHelp;
	private boolean wantVersion;
	private int maxParamLength;

	public <P> P parse(Class<P> paramInterface, String... args) {
		if (!paramInterface.isInterface()) {
			throw new IllegalArgumentException(paramInterface + " must be an interface");
		}
		return createProxy(paramInterface, args);
	}

	public Map<String, Param> getValidParams() {
		return paramMap;
	}

	public Map<String, Object> getConvertedParams() {
		return convertedParamMap;
	}

	public List<String> getAdditionalParams() {
		return additionalParams;
	}

	public List<String> getErrors() {
		return errors;
	}

	private <P> P createProxy(Class<P> paramInterface, String... args) {

		Map<String, MethodParamPair> params = new HashMap<String, MethodParamPair>();
		paramMap.clear();
		convertedParamMap.clear();
		wantHelp = false;
		wantVersion = false;
		for (Method method : paramInterface.getDeclaredMethods()) {
			Option option = ReflectionUtils.getOptionAnnotation(method);
			String name = getParameterName(method, option);
			if (name.length() > maxParamLength) {
				maxParamLength = name.length();
			}
			String description = option.description();
			String defaultValue = option.defaultValue();
			if (defaultValue.equals(Option.OPTIONAL)) {
				defaultValue = null;
			}
			Class<?> returnType = ReflectionUtils.getBoxedClass(method.getReturnType());
			Param param = new Param(name, description, defaultValue, returnType);
			paramMap.put(name, param);
			MethodParamPair pair = new MethodParamPair(method, param);
			params.put(name, pair);
		}

		Map<Method, Object> valuesMap = convert(params, args);
		for (Map.Entry<Method, Object> entry : valuesMap.entrySet()) {
			Method method = entry.getKey();
			Option option = ReflectionUtils.getOptionAnnotation(method);
			String name = getParameterName(method, option);
			convertedParamMap.put(name, entry.getValue());
		}

		if (wantHelp) {
			displayUsage();
			System.exit(0);
		}
		if (wantVersion){
			System.err.println("splitter " + Version.VERSION + " compiled " + Version.TIMESTAMP);
			System.exit(0); 
		}
		ParamInvocationHandler invocationHandler = new ParamInvocationHandler(valuesMap);
		return (P) Proxy.newProxyInstance(paramInterface.getClassLoader(), new Class<?>[]{paramInterface}, invocationHandler);
	}

	private Map<Method, Object> convert(Map<String, MethodParamPair> paramMap, String[] args) {
		Map<Method, Object> result = new HashMap<Method, Object>(10);

		// First set up the defaults
		for (MethodParamPair pair : paramMap.values()) {
			Method method = pair.getMethod();
			Param param = pair.getParam();
			Object value = converter.convert(param, param.getDefaultValue());
			if (value == null && method.getReturnType().isPrimitive()) {
				result.put(method, converter.getPrimitiveDefault(method.getReturnType()));
			} else {
				result.put(method, value);
			}
		}

		// Now override these with any parameters that were specified on the command line
		HashMap<String,String> parsedArgs = new HashMap<String, String>();
		for (String arg : args) {
			if (arg.startsWith("--")) {
				String name;
				String value;
				int j = arg.indexOf('=');
				if (j > 0) {
					name = arg.substring(2, j);
					value = arg.substring(j + 1);
				} else {
					// Should be a boolean
					name = arg.substring(2);
					value = null;
				}
				
				// warn user regarding duplicated parms
				String testVal = value==null? "no val":value;
				String oldVal = parsedArgs.put(name, testVal);
				if (oldVal != null && oldVal.equals(testVal) == false){
					System.err.println("Warning: repeated paramter overwrites previous value: --" + name + (value==null? "":"="+value));
				}
				
				MethodParamPair pair = paramMap.get(name);
				if (pair != null) {
					if (pair.getParam().getReturnType() == Boolean.class && value == null) {
						result.put(pair.getMethod(), Boolean.TRUE);
					} else {
						try {
							Object convertedVal = converter.convert(pair.getParam(), value);
							result.put(pair.getMethod(), convertedVal);
						} catch (Exception e) {
							errors.add("Unable to parse " + arg + ". Reason: " + e.getMessage());
						}
					}
				} else {
					// Unknown parameter
					if ("help".equals(name)) {
						wantHelp = true;
					} else if ("version".equals(name)){
						wantVersion = true;
					} else {
						errors.add("Parameter " + arg + " is not recognised, ignoring");
					}
				}
			} else {
				// We have a parameter that doesn't start with --
				additionalParams.add(arg);
			}
		}
		return result;
	}

	public <P> void displayUsage() {
		System.out.println("Usage: java [JAVA_OPTIONS] -jar splitter.jar [OPTIONS] input_file (*.osm or *.pbf or *.o5m)");
		System.out.println("Options:");
		StringBuilder buf = new StringBuilder(100);
		for (Param param : paramMap.values()) {
			buf.setLength(0);
			buf.append(" --").append(param.getName());
			for (int i = 0; i < maxParamLength - param.getName().length() + 2; i++) {
				buf.append(' ');
			}
			buf.append(param.getDescription());
			if (param.getDefaultValue() != null) {
				buf.append(" Default is ").append(param.getDefaultValue()).append('.');
			}
			System.out.println(buf.toString());
		}
	}

	private <P> String getParameterName(Method method, Option option) {
		return option.name().length() == 0 ? ReflectionUtils.getParamName(method) : option.name();
	}

	private static class ParamInvocationHandler implements InvocationHandler {
		private final Map<Method, Object> valuesMap;

		private ParamInvocationHandler(Map<Method, Object> valuesMap) {
			this.valuesMap = valuesMap;
		}

		@Override
		public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
			return valuesMap.get(method);
		}
	}

	private static class MethodParamPair {
		private final Method method;
		private final Param param;

		private MethodParamPair(Method method, Param param) {
			this.method = method;
			this.param = param;
		}

		public Method getMethod() {
			return method;
		}

		public Param getParam() {
			return param;
		}
	}
}
