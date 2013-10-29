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

import uk.me.parabola.splitter.Relation.Member;

import java.io.IOException;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.Date;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

/**
 * Splits a map into multiple areas.
 */
class SplitProcessor extends AbstractMapProcessor {
	private final OSMWriter[] writers;

	private SparseLong2ShortMapFunction coords;
	private SparseLong2ShortMapFunction ways; 	
	private final WriterDictionaryShort writerDictionary;
	private final DataStorer dataStorer;
	private final Long2IntClosedMapFunction nodeWriterMap;
	private final Long2IntClosedMapFunction wayWriterMap;
	private final Long2IntClosedMapFunction relWriterMap;

	//	for statistics
	private long countQuickTest = 0;
	private long countFullTest = 0;
	private long countCoords = 0;
	private long countWays = 0;
	private final int writerOffset;
	private final int lastWriter;
	private WriterIndex writerIndex;
	private final int maxThreads;
	private final short unassigned = Short.MIN_VALUE;

	private final InputQueueInfo[] writerInputQueues;
	private final BlockingQueue<InputQueueInfo> toProcess;
	private final ArrayList<Thread> workerThreads;
	private final InputQueueInfo STOP_MSG = new InputQueueInfo(null);


	// private int currentNodeAreaSet;
	private BitSet currentWayAreaSet;
	private BitSet currentRelAreaSet;
	private BitSet usedWriters;
	
	
	SplitProcessor(DataStorer dataStorer,
			int writerOffset, int numWritersThisPass, int maxThreads){
		this.dataStorer = dataStorer;
		this.writerDictionary = dataStorer.getWriterDictionary();
		this.writers = writerDictionary.getWriters();
		this.coords = new SparseLong2ShortMapInline();
		this.ways   = new SparseLong2ShortMapInline();
		this.coords.defaultReturnValue(unassigned);
		this.ways.defaultReturnValue(unassigned); 		
		this.writerIndex = dataStorer.getGrid();
		this.countWays = ways.size();
		this.writerOffset = writerOffset;
		this.lastWriter = writerOffset + numWritersThisPass-1;
		this.maxThreads = maxThreads;
		this.toProcess = new ArrayBlockingQueue<InputQueueInfo>(numWritersThisPass);
		this.writerInputQueues = new InputQueueInfo[numWritersThisPass];
		for (int i = 0; i < writerInputQueues.length; i++) {
			writerInputQueues[i] = new InputQueueInfo(this.writers[i + writerOffset]);
			writers[i + writerOffset].initForWrite(); 
		}
		nodeWriterMap = dataStorer.getWriterMap(DataStorer.NODE_TYPE);
		wayWriterMap = dataStorer.getWriterMap(DataStorer.WAY_TYPE);
		relWriterMap = dataStorer.getWriterMap(DataStorer.REL_TYPE);
		currentWayAreaSet = new BitSet(writers.length);
		currentRelAreaSet = new BitSet(writers.length);
		usedWriters = new BitSet(); 

		int noOfWorkerThreads = Math.min(this.maxThreads - 1, numWritersThisPass);
		workerThreads = new ArrayList<Thread>(noOfWorkerThreads);
		for (int i = 0; i < noOfWorkerThreads; i++) {
			Thread worker = new Thread(new OSMWriterWorker());
			worker.setName("worker-" + i);
			workerThreads.add(worker);
			worker.start();
		}
		
	} 

	@Override
	public void processNode(Node n) {
		try {
			writeNode(n);
		} catch (IOException e) {
			throw new RuntimeException("failed to write node " + n.getId(), e);
		}
	}

	@Override
	public void processWay(Way w) {
		currentWayAreaSet.clear();
		int multiTileWriterIdx = (wayWriterMap != null) ? wayWriterMap.getSeq(w.getId()): WriterDictionaryInt.UNASSIGNED;
		if (multiTileWriterIdx != WriterDictionaryInt.UNASSIGNED){
			BitSet cl = dataStorer.getMultiTileWriterDictionary().getBitSet(multiTileWriterIdx);
			// set only active writer bits
			for(int i=cl.nextSetBit(writerOffset); i>=0 && i <= lastWriter; i=cl.nextSetBit(i+1)){
				currentWayAreaSet.set(i);
			}
			//System.out.println("added or completed way: " +  w.getId());
		}
		else{
			short oldclIndex = unassigned;
			//for (long id : w.getRefs()) {
			int refs = w.getRefs().size();
			for (int i = 0; i < refs; i++){
				long id = w.getRefs().getLong(i);
				// Get the list of areas that the way is in. 
				short clIdx = coords.get(id);
				if (clIdx != unassigned){
					if (oldclIndex != clIdx){ 
						BitSet cl = writerDictionary.getBitSet(clIdx);
						currentWayAreaSet.or(cl);
						oldclIndex = clIdx;
					}
				}
			}
		}
		if (!currentWayAreaSet.isEmpty()){
			// store these areas in ways map
			short idx = writerDictionary.translate(currentWayAreaSet);
			ways.put(w.getId(), idx);
			++countWays;
			if (countWays % 1000000 == 0){
				System.out.println("MAP occupancy: " + Utils.format(countWays) + ", number of area dictionary entries: " + writerDictionary.size() + " of " + ((1<<16) - 1));
				ways.stats(0);
			}
		}
		try {
			writeWay(w);
		} catch (IOException e) {
			throw new RuntimeException("failed to write way " + w.getId(), e);
		}
	}

	@Override
	public void processRelation(Relation rel) {
		currentRelAreaSet.clear();
		int multiTileWriterIdx = (relWriterMap != null) ? relWriterMap.getSeq(rel.getId()): WriterDictionaryInt.UNASSIGNED;
		if (multiTileWriterIdx != WriterDictionaryInt.UNASSIGNED){
			
			BitSet cl = dataStorer.getMultiTileWriterDictionary().getBitSet(multiTileWriterIdx);
			try {
				// set only active writer bits
				for(int i=cl.nextSetBit(writerOffset); i>=0 && i <= lastWriter; i=cl.nextSetBit(i+1)){
					currentRelAreaSet.set(i);
				}
				writeRelation(rel);
				//System.out.println("added rel: " +  r.getId());
			} catch (IOException e) {
				throw new RuntimeException("failed to write relation " + rel.getId(),
						e);
			}
		}
		else{
			short oldclIndex = unassigned;
			short oldwlIndex = unassigned;
			try {
				for (Member mem : rel.getMembers()) {
					// String role = mem.getRole();
					long id = mem.getRef();
					if (mem.getType().equals("node")) {
						short clIdx = coords.get(id);

						if (clIdx != unassigned){
							if (oldclIndex != clIdx){ 
								BitSet wl = writerDictionary.getBitSet(clIdx);
								currentRelAreaSet.or(wl);
							}
							oldclIndex = clIdx;

						}

					} else if (mem.getType().equals("way")) {
						short wlIdx = ways.get(id);

						if (wlIdx != unassigned){
							if (oldwlIndex != wlIdx){ 
								BitSet wl = writerDictionary.getBitSet(wlIdx);
								currentRelAreaSet.or(wl);
							}
							oldwlIndex = wlIdx;
						}
					}
				}

				writeRelation(rel);
			} catch (IOException e) {
				throw new RuntimeException("failed to write relation " + rel.getId(),
						e);
			}
		}
	}
	@Override
	public boolean endMap() {
		System.out.println("Statistics for coords map:");
		coords.stats(1);
		System.out.println("");
		System.out.println("Statistics for ways map:");
		ways.stats(1);
		Utils.printMem();
		System.out.println("Full Node tests:  " + Utils.format(countFullTest));
		System.out.println("Quick Node tests: " + Utils.format(countQuickTest)); 		
		coords = null;
		ways = null;

		for (int i = 0; i < writerInputQueues.length; i++) {
			try {
				writerInputQueues[i].stop();
			} catch (InterruptedException e) {
				throw new RuntimeException(
						"Failed to add the stop element for worker thread " + i,
						e);
			}
		}
		try {
			if (maxThreads > 1)
				toProcess.put(STOP_MSG);// Magic flag used to indicate that all data is done.

		} catch (InterruptedException e1) {
			e1.printStackTrace();
		}

		for (Thread workerThread : workerThreads) {
			try {
				workerThread.join();
			} catch (InterruptedException e) {
				throw new RuntimeException("Failed to join for thread "
						+ workerThread.getName(), e);
			}
		}
		for (int i=writerOffset; i<= lastWriter; i++) {
			writers[i].finishWrite();
		}
		return true; 		
	}

	private void writeNode(Node currentNode) throws IOException {
		int countWriters = 0;
		short lastUsedWriter = unassigned;
		WriterGridResult writerCandidates = writerIndex.get(currentNode);
		int multiTileWriterIdx = (nodeWriterMap != null) ? nodeWriterMap.getSeq(currentNode.getId()): WriterDictionaryInt.UNASSIGNED;

		boolean isSpecialNode = (multiTileWriterIdx != WriterDictionaryInt.UNASSIGNED);
		if (writerCandidates == null && !isSpecialNode)  {
			return;
		}
		if (isSpecialNode || writerCandidates.l.size() > 1)
			usedWriters.clear();
		if (writerCandidates != null){
			for (int i = 0; i < writerCandidates.l.size(); i++) {
				int n = writerCandidates.l.getShort(i);
				if (n < writerOffset || n > lastWriter)
					continue;
				OSMWriter w = writers[n];
				boolean found;
				if (writerCandidates.testNeeded){
					found = w.nodeBelongsToThisArea(currentNode);
					++countFullTest;
				}
				else{ 
					found = true;
					++countQuickTest;
				}
				if (found) {
					usedWriters.set(n);
					++countWriters;
					lastUsedWriter = (short) n;
					if (maxThreads > 1) {
						addToWorkingQueue(n, currentNode);
					} else {
						w.write(currentNode);
					}
				}
			}
		}
		if (isSpecialNode){
			// this node is part of a multi-tile-polygon, add it to all tiles covered by the parent 
			BitSet nodeWriters = dataStorer.getMultiTileWriterDictionary().getBitSet(multiTileWriterIdx);
			for(int i=nodeWriters.nextSetBit(writerOffset); i>=0 && i <= lastWriter; i=nodeWriters.nextSetBit(i+1)){
				if (usedWriters.get(i) )
					continue;
				if (maxThreads > 1) {
					addToWorkingQueue(i, currentNode);
				} else {
					writers[i].write(currentNode);
				}
			}
		}
		
		if (countWriters > 0){
			short writersID;
			if (countWriters > 1)
				writersID = writerDictionary.translate(usedWriters);
			else  
				writersID = (short) (lastUsedWriter  - WriterDictionaryShort.DICT_START); // no need to do lookup in the dictionary 
			coords.put(currentNode.getId(), writersID);
			++countCoords;
			if (countCoords % 10000000 == 0){
				System.out.println("MAP occupancy: " + Utils.format(countCoords) + ", number of area dictionary entries: " + writerDictionary.size() + " of " + ((1<<16) - 1));
				coords.stats(0);
			}
		}
	}

	private boolean seenWay;

	private void writeWay(Way currentWay) throws IOException {
		if (!seenWay) {
			seenWay = true;
			System.out.println("Writing ways " + new Date());
		}
		
		if (!currentWayAreaSet.isEmpty()) {
				for (int n = currentWayAreaSet.nextSetBit(0); n >= 0; n = currentWayAreaSet.nextSetBit(n + 1)) {
					if (maxThreads > 1) {
						addToWorkingQueue(n, currentWay);
					} else {
						writers[n].write(currentWay);
					}
				}
			}
	}

	private boolean seenRel;

	private void writeRelation(Relation currentRelation) throws IOException {
		if (!seenRel) {
			seenRel = true;
			System.out.println("Writing relations " + new Date());
		}
		for (int n = currentRelAreaSet.nextSetBit(0); n >= 0; n = currentRelAreaSet.nextSetBit(n + 1)) {
			// if n is out of bounds, then something has gone wrong
			if (maxThreads > 1) {
				addToWorkingQueue(n, currentRelation);
			} else {
				writers[n].write(currentRelation);
			}
		}
	}

	private void addToWorkingQueue(int writerNumber, Element element) {
		try {
			writerInputQueues[writerNumber-writerOffset].put(element);
		} catch (InterruptedException e) {
			// throw new RuntimeException("Failed to write node " +
			// element.getId() + " to worker thread " + writerNumber, e);
		}
	}

	private class InputQueueInfo {
		private final OSMWriter writer;
		private ArrayList<Element> staging;
		private final BlockingQueue<ArrayList<Element>> inputQueue;

		public InputQueueInfo(OSMWriter writer) {
			inputQueue =  new ArrayBlockingQueue<ArrayList<Element>>(NO_ELEMENTS);
			this.writer = writer;
			this.staging = new ArrayList<Element>(STAGING_SIZE);
		}

		void put(Element e) throws InterruptedException {
			staging.add(e);
			if (staging.size() < STAGING_SIZE)
				return;
			flush();
		}

		void flush() throws InterruptedException {
			// System.out.println("Flush");
			inputQueue.put(staging);
			staging = new ArrayList<Element>(STAGING_SIZE);
			toProcess.put(this);
		}

		void stop() throws InterruptedException {
			flush();
		}
	}

	public static final int NO_ELEMENTS = 3;
	final int STAGING_SIZE = 300;

	private class OSMWriterWorker implements Runnable {

		public void processElement(Element element, OSMWriter writer)
				throws IOException {
			if (element instanceof Node) {
				writer.write((Node) element);
			} else if (element instanceof Way) {
				writer.write((Way) element);
			} else if (element instanceof Relation) {
				writer.write((Relation) element);
			}
		}

		@Override
		public void run() {
			boolean finished = false;
			while (!finished) {
				InputQueueInfo workPackage = null;
				try {
					workPackage = toProcess.take();
				} catch (InterruptedException e1) {
					e1.printStackTrace();
					continue;
				}
				if (workPackage == STOP_MSG) {
					try {
						toProcess.put(STOP_MSG); // Re-inject it so that other
													// threads know that we're
													// exiting.
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
					finished = true;
				} else {
					synchronized (workPackage) {
					while (!workPackage.inputQueue.isEmpty()) {
							ArrayList<Element> elements = null;
						try {
							elements = workPackage.inputQueue.poll();
								for (Element element : elements) {
								processElement(element, workPackage.writer);
							}

						} catch (IOException e) {
								throw new RuntimeException("Thread "
										+ Thread.currentThread().getName()
										+ " failed to write element ", e);
						}
					}
					}

				}
			}
			System.out.println("Thread " + Thread.currentThread().getName()
					+ " has finished");
		}
	}

}
