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

/**
 * Periodically outputs the elapsed time and amount of memory used by the VM
 *
 * @author Chris Miller
 */
public class JVMHealthMonitor {
	private JVMHealthMonitor() {
	}

	private static Thread statusThread;
	private static long startTime;

	/**
	 * Starts a daemon thread that will periodically report the state of the JVM (heap usage).
	 * This method just needs to be called once and there's nothing else to do. The background
	 * thread will terminate automatically when the application exits.
	 *
	 * @param statusFrequency the number of seconds to sleep between each status update.
	 */
	public static void start(final long statusFrequency) {
		if (statusThread != null) {
			throw new IllegalStateException("A JVMHealthMonitor thread is already running. JVMHealthMonitor.start() must only be called once during the lifetime of an application.");
		}
		startTime = System.currentTimeMillis();
		statusThread = new Thread(new Runnable() {
			@Override
			public void run() {
				int iter=0;
				while (true) {
					iter++;
					if (iter%10 == 0) {
						System.out.println("***** Full GC *****");
						System.gc();
					}
					long maxMem = Runtime.getRuntime().maxMemory() / 1024 / 1024;
					long totalMem = Runtime.getRuntime().totalMemory() / 1024 / 1024;
					long freeMem = Runtime.getRuntime().freeMemory() / 1024 / 1024;
					long usedMem = totalMem - freeMem;
					System.out.println("Elapsed time: " + getElapsedTime() + "   Memory: Current " + totalMem + "MB (" + usedMem + "MB used, " + freeMem + "MB free) Max " + maxMem + "MB");
					try {
						Thread.sleep(statusFrequency * 1000L);
					}
					catch (InterruptedException e) {
						System.out.println("JVMHealthMonitor sleep was interrupted. Ignoring.");
					}
				}
			}
		}
		);
		statusThread.setDaemon(true);
		statusThread.setName("JVMHealthMonitor");
		statusThread.start();
	}

	private static String getElapsedTime() {
		long elapsed = (System.currentTimeMillis() - startTime) / 1000;
		long seconds = elapsed % 60;
		long minutes = elapsed / 60 % 60;
		long hours = elapsed / (60L * 60) % 60;
		StringBuilder buf = new StringBuilder(20);
		if (hours > 0)
			buf.append(hours).append("h ");
		if (hours > 0 || minutes > 0)
			buf.append(minutes).append("m ");
		buf.append(seconds).append('s');
		return buf.toString();
	}
}