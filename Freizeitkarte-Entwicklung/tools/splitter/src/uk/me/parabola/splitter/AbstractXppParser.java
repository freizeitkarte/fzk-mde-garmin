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

import java.io.IOException;
import java.io.Reader;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

/**
 * Base functionality for an XPP based XML parser
 */
public abstract class AbstractXppParser {
	private final XmlPullParser parser;

	public AbstractXppParser() throws XmlPullParserException {
		XmlPullParserFactory factory = XmlPullParserFactory.newInstance(System.getProperty(XmlPullParserFactory.PROPERTY_NAME), null);
		parser = factory.newPullParser();
	}

	protected void setReader(Reader reader) throws XmlPullParserException {
		parser.setInput(reader);
	}

	protected String getAttr(String name) {
		return parser.getAttributeValue(null, name);
	}

	protected int getIntAttr(String name) {
		return Integer.parseInt(parser.getAttributeValue(null, name));
	}
	
	protected long getLongAttr(String name) {
		return Long.parseLong(parser.getAttributeValue(null, name));
	}

	protected String getTextContent() {
		return parser.getText();
	}

	protected void parse() throws IOException, XmlPullParserException {
		boolean done = false;
		int eventType = parser.getEventType();
		do {
			if (eventType == XmlPullParser.START_TAG) {
				done = startElement(parser.getName());
			} else if (eventType == XmlPullParser.END_TAG) {
				endElement(parser.getName());
			} else if (eventType == XmlPullParser.TEXT) {
				text();
			}
		}
		while (!done && (eventType = parser.next()) != XmlPullParser.END_DOCUMENT);
	}

	protected XmlPullParserException createException(String message) {
		return new XmlPullParserException(message, parser, null);
	}
	/**
	 * Called when the start of an element is encountered.
	 * @param name the name of the element.
	 * @return {@code true} to abort the parsing because there's
	 * no further processing required, {@code false} otherwise.
	 * @throws XmlPullParserException
	 */
	abstract protected boolean startElement(String name) throws XmlPullParserException;

	abstract protected void endElement(String name) throws XmlPullParserException;

	protected void text() throws XmlPullParserException {
	}
}
