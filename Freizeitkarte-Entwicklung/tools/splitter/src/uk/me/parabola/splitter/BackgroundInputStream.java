/*
 * Copyright (c) 2010.
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
import java.io.InputStream;
import java.util.Arrays;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class BackgroundInputStream extends InputStream {
	private static final int QUEUE_SIZE = 5;
	private static final int BUFFER_SIZE = 32768;
	private static final byte[] EOF_MARKER = new byte[0];

	// These variables are accessed from both threads
	private final BlockingQueue<byte[]> inQueue;
	private final BlockingQueue<byte[]> recycleQueue;
	private final int bufferSize;
	private final InputStream sourceStream;
	private volatile boolean closed;

	// These variables are only accessed from the reader thread
	private byte[] currentBuffer;
	private int currentIndex;
	private Thread loaderThread;

	public BackgroundInputStream(InputStream source) {
		this(source, QUEUE_SIZE, BUFFER_SIZE);
	}

	public BackgroundInputStream(InputStream source, int queueSize, int bufferSize)
	{
		inQueue = new ArrayBlockingQueue<byte[]>(queueSize);
		recycleQueue = new ArrayBlockingQueue<byte[]>(queueSize + 1);
		sourceStream = source;
		this.bufferSize = bufferSize;
	}

	@Override
	public int read() throws IOException {
		if (!ensureBuffer()) {
			return -1;
		}
		int b = currentBuffer[currentIndex++];
		recycle();
		return b;
	}

	@Override
	public int read(byte[] b) throws IOException {
		return read(b, 0, b.length);
	}

	@Override
	public int read(byte[] b, int off, int len) throws IOException {
		int count = 0;
		while (len > 0) {
			if (!ensureBuffer()) {
				return count == 0 ? -1 : count;
			}
			int remaining = currentBuffer.length - currentIndex;
			int bytesToCopy = Math.min(remaining, len);
			System.arraycopy(currentBuffer, currentIndex, b, off, bytesToCopy);
			count += bytesToCopy;
			currentIndex += bytesToCopy;
			off += bytesToCopy;
			len -= bytesToCopy;
			recycle();
		}
		return count;
	}

	private boolean ensureBuffer() throws IOException {
		if (loaderThread == null) {
			loaderThread = new Thread(new Loader(), "BackgroundInputStream");
			loaderThread.start();
		}
		if (currentBuffer == null) {
			try {
				currentBuffer = inQueue.take();
			} catch (InterruptedException e) {
				throw new IOException("Failed to take a buffer from the queue", e);
			}
			currentIndex = 0;
		}
		return currentBuffer != EOF_MARKER;
	}

	private void recycle() {
		if (currentIndex == currentBuffer.length) {
			if (currentIndex == bufferSize) {
				recycleQueue.offer(currentBuffer);
			}
			currentBuffer = null;
		}
	}

	@Override
	public int available() throws IOException {
		return currentBuffer == null ? 0 : currentBuffer.length;
	}

	@Override
	public void close() throws IOException {
		closed = true;
		inQueue.clear();
		recycleQueue.clear();
		currentBuffer = null;
	}

	private class Loader implements Runnable {
		@Override
		public void run() {
			{
				int bytesRead = 0;
				while (!closed) {
					byte[] buffer = recycleQueue.poll();
					if (buffer == null) {
						buffer = new byte[bufferSize];
					}
					int offset = 0;
					try {
						while ((offset < bufferSize) && ((bytesRead = sourceStream.read(buffer, offset, bufferSize - offset)) != -1)) {
							offset += bytesRead;
						}
					} catch (IOException e) {
						throw new RuntimeException("Unable to read from stream", e);
					}
					if (offset < bufferSize) {
						buffer = Arrays.copyOf(buffer, offset);
					}
					try {
						inQueue.put(buffer);
						if (bytesRead == -1) {
							inQueue.put(EOF_MARKER);
							closed = true;
						}
					} catch (InterruptedException e) {
						throw new RuntimeException("Unable to put data onto queue", e);
					}
					if (closed) {
						try {
							sourceStream.close();
						} catch (IOException e) {
							throw new RuntimeException("Unable to close source stream", e);
						}
					}
				}
			}
		}
	}
}
