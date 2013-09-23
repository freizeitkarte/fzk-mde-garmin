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

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;

import uk.me.parabola.splitter.Relation.Member;
import crosby.binary.BinarySerializer;
import crosby.binary.Osmformat;
import crosby.binary.StringTable;
import crosby.binary.Osmformat.DenseInfo;
import crosby.binary.Osmformat.Relation.MemberType;
import crosby.binary.file.BlockOutputStream;
import crosby.binary.file.FileBlock;

public class BinaryMapWriter extends AbstractOSMWriter {

  private PBFSerializer serializer;

  private BlockOutputStream output;

  protected boolean useDense = true;

  protected boolean headerWritten = false;

  public class PBFSerializer extends BinarySerializer {

    public PBFSerializer(BlockOutputStream output)
    {
      super(output);
      configBatchLimit(1000);
      omit_metadata = true;
    }

    /** Base class containing common code needed for serializing each type of primitives. */
    private abstract class Prim<T extends Element> {
      /** Queue that tracks the list of all primitives. */
      ArrayList<T> contents = new ArrayList<T>();

      /** Add to the queue.
       * @param item The entity to add */
      public void add(T item)
      {
        contents.add(item);
      }

      /** Add all of the tags of all entities in the queue to the stringtable. */
      public void addStringsToStringtable()
      {
        StringTable stable = getStringTable();
        for(T i : contents) {
          Iterator<Element.Tag> tags = i.tagsIterator();
          while(tags.hasNext()) {
            Element.Tag tag = tags.next();
            stable.incr(tag.getKey());
            stable.incr(tag.getValue());
          }
          if(!omit_metadata) {
            //            stable.incr(i.getUser().getName());
          }
        }
      }

      //      private static final int MAXWARN = 100;

      public void serializeMetadataDense(DenseInfo.Builder b,
          List<? extends Element> entities)
      {
        if(omit_metadata) {
          return;
        }

        //        long lasttimestamp = 0, lastchangeset = 0;
        //        int lastuserSid = 0, lastuid = 0;
        //        StringTable stable = serializer.getStringTable();
        //        for(Element e : entities) {
        //
        //          if(e.getUser() == OsmUser.NONE && warncount < MAXWARN) {
        //            LOG
        //                .warning("Attention: Data being output lacks metadata. Please use omitmetadata=true");
        //            warncount++;
        //          }
        //          int uid = e.getUser().getId();
        //          int userSid = stable.getIndex(e.getUser().getName());
        //          int timestamp = (int)(e.getTimestamp().getTime() / date_granularity);
        //          int version = e.getVersion();
        //          long changeset = e.getChangesetId();
        //
        //          b.addVersion(version);
        //          b.addTimestamp(timestamp - lasttimestamp);
        //          lasttimestamp = timestamp;
        //          b.addChangeset(changeset - lastchangeset);
        //          lastchangeset = changeset;
        //          b.addUid(uid - lastuid);
        //          lastuid = uid;
        //          b.addUserSid(userSid - lastuserSid);
        //          lastuserSid = userSid;
        //        }
      }

      public Osmformat.Info.Builder serializeMetadata(Element e)
      {
        //        StringTable stable = serializer.getStringTable();
        Osmformat.Info.Builder b = Osmformat.Info.newBuilder();
        if(!omit_metadata) {
          //          if(e.getUser() == OsmUser.NONE && warncount < MAXWARN) {
          //            LOG
          //                .warning("Attention: Data being output lacks metadata. Please use omitmetadata=true");
          //            warncount++;
          //          }
          //          if(e.getUser() != OsmUser.NONE) {
          //            b.setUid(e.getUser().getId());
          //            b.setUserSid(stable.getIndex(e.getUser().getName()));
          //          }
          //          b.setTimestamp((int)(e.getTimestamp().getTime() / date_granularity));
          //          b.setVersion(e.getVersion());
          //          b.setChangeset(e.getChangesetId());
        }
        return b;
      }
    }

    private class NodeGroup extends Prim<Node> implements
        PrimGroupWriterInterface {

      public Osmformat.PrimitiveGroup serialize()
      {
        if(useDense) {
          return serializeDense();
        } else {
          return serializeNonDense();
        }
      }

      /**
       *  Serialize all nodes in the 'dense' format.
       */
      public Osmformat.PrimitiveGroup serializeDense()
      {
        if(contents.size() == 0) {
          return null;
        }
        // System.out.format("%d Dense   ",nodes.size());
        Osmformat.PrimitiveGroup.Builder builder = Osmformat.PrimitiveGroup
            .newBuilder();
        StringTable stable = serializer.getStringTable();

        long lastlat = 0, lastlon = 0, lastid = 0;
        Osmformat.DenseNodes.Builder bi = Osmformat.DenseNodes.newBuilder();
        boolean doesBlockHaveTags = false;
        // Does anything in this block have tags?
        for(Node i : contents) {
          doesBlockHaveTags = doesBlockHaveTags || (i.tagsIterator().hasNext());
        }
        if(!omit_metadata) {
          Osmformat.DenseInfo.Builder bdi = Osmformat.DenseInfo.newBuilder();
          serializeMetadataDense(bdi, contents);
          bi.setDenseinfo(bdi);
        }

        for(Node i : contents) {
          long id = i.getId();
          int lat = mapDegrees(i.getLat());
          int lon = mapDegrees(i.getLon());
          bi.addId(id - lastid);
          lastid = id;
          bi.addLon(lon - lastlon);
          lastlon = lon;
          bi.addLat(lat - lastlat);
          lastlat = lat;

          // Then we must include tag information.
          if(doesBlockHaveTags) {
            Iterator<Element.Tag> tags = i.tagsIterator();
            while(tags.hasNext()) {
              Element.Tag t = tags.next();
              bi.addKeysVals(stable.getIndex(t.getKey()));
              bi.addKeysVals(stable.getIndex(t.getValue()));
            }
            bi.addKeysVals(0); // Add delimiter.
          }
        }
        builder.setDense(bi);
        return builder.build();
      }

      /**
       *  Serialize all nodes in the non-dense format.
       * 
       * @param parentbuilder Add to this PrimitiveBlock.
       */
      public Osmformat.PrimitiveGroup serializeNonDense()
      {
        if(contents.size() == 0) {
          return null;
        }
        // System.out.format("%d Nodes   ",nodes.size());
        StringTable stable = serializer.getStringTable();
        Osmformat.PrimitiveGroup.Builder builder = Osmformat.PrimitiveGroup
            .newBuilder();
        for(Node i : contents) {
          long id = i.getId();
          int lat = mapDegrees(i.getLat());
          int lon = mapDegrees(i.getLon());
          Osmformat.Node.Builder bi = Osmformat.Node.newBuilder();
          bi.setId(id);
          bi.setLon(lon);
          bi.setLat(lat);
          Iterator<Element.Tag> tags = i.tagsIterator();
          while(tags.hasNext()) {
            Element.Tag t = tags.next();
            bi.addKeys(stable.getIndex(t.getKey()));
            bi.addVals(stable.getIndex(t.getValue()));
          }
          if(!omit_metadata) {
            bi.setInfo(serializeMetadata(i));
          }
          builder.addNodes(bi);
        }
        return builder.build();
      }

    }

    private class WayGroup extends Prim<Way> implements
        PrimGroupWriterInterface {
      public Osmformat.PrimitiveGroup serialize()
      {
        if(contents.size() == 0) {
          return null;
        }

        // System.out.format("%d Ways  ",contents.size());
        StringTable stable = serializer.getStringTable();
        Osmformat.PrimitiveGroup.Builder builder = Osmformat.PrimitiveGroup
            .newBuilder();
        for(Way i : contents) {
          Osmformat.Way.Builder bi = Osmformat.Way.newBuilder();
          bi.setId(i.getId());
          long lastid = 0;
          for(long j : i.getRefs()) {
            long id = j;
            bi.addRefs(id - lastid);
            lastid = id;
          }
          Iterator<Element.Tag> tags = i.tagsIterator();
          while(tags.hasNext()) {
            Element.Tag t = tags.next();
            bi.addKeys(stable.getIndex(t.getKey()));
            bi.addVals(stable.getIndex(t.getValue()));
          }
          if(!omit_metadata) {
            bi.setInfo(serializeMetadata(i));
          }
          builder.addWays(bi);
        }
        return builder.build();
      }
    }

    private class RelationGroup extends Prim<Relation> implements
        PrimGroupWriterInterface {
      public void addStringsToStringtable()
      {
        StringTable stable = serializer.getStringTable();
        super.addStringsToStringtable();
        for(Relation i : contents) {
          for(Member j : i.getMembers()) {
            stable.incr(j.getRole());
          }
        }
      }

      public Osmformat.PrimitiveGroup serialize()
      {
        if(contents.size() == 0) {
          return null;
        }

        // System.out.format("%d Relations  ",contents.size());
        StringTable stable = serializer.getStringTable();
        Osmformat.PrimitiveGroup.Builder builder = Osmformat.PrimitiveGroup
            .newBuilder();
        for(Relation i : contents) {
          Osmformat.Relation.Builder bi = Osmformat.Relation.newBuilder();
          bi.setId(i.getId());
          Member[] arr = new Member[i.getMembers().size()];
          i.getMembers().toArray(arr);
          long lastid = 0;
          for(Member j : i.getMembers()) {
            long id = j.getRef();
            bi.addMemids(id - lastid);
            lastid = id;
            if(j.getType().equals("node")) {
              bi.addTypes(MemberType.NODE);
            } else if(j.getType().equals("way")) {
              bi.addTypes(MemberType.WAY);
            } else if(j.getType().equals("relation")) {
              bi.addTypes(MemberType.RELATION);
            } else {
              assert (false); // Software bug: Unknown entity.
            }
            bi.addRolesSid(stable.getIndex(j.getRole()));
          }

          Iterator<Element.Tag> tags = i.tagsIterator();
          while(tags.hasNext()) {
            Element.Tag t = tags.next();
            bi.addKeys(stable.getIndex(t.getKey()));
            bi.addVals(stable.getIndex(t.getValue()));
          }
          if(!omit_metadata) {
            bi.setInfo(serializeMetadata(i));
          }
          builder.addRelations(bi);
        }
        return builder.build();
      }
    }

    /* One list for each type */
    private WayGroup ways;

    private NodeGroup nodes;

    private RelationGroup relations;

    private Processor processor = new Processor();

    /**
     * Buffer up events into groups that are all of the same type, or all of the
     * same length, then process each buffer.
     */
    public class Processor {

      /**
       * Check if we've reached the batch size limit and process the batch if
       * we have.
       */
      public void checkLimit()
      {
        total_entities++;
        if(++batch_size < batch_limit) {
          return;
        }
        switchTypes();
        processBatch();
      }

      public void process(Node node)
      {
        if(nodes == null) {
          writeEmptyHeaderIfNeeded();
          // Need to switch types.
          switchTypes();
          nodes = new NodeGroup();
        }
        nodes.add(node);
        checkLimit();
      }

      public void process(Way way)
      {
        if(ways == null) {
          writeEmptyHeaderIfNeeded();
          switchTypes();
          ways = new WayGroup();
        }
        ways.add(way);
        checkLimit();
      }

      public void process(Relation relation)
      {
        if(relations == null) {
          writeEmptyHeaderIfNeeded();
          switchTypes();
          relations = new RelationGroup();
        }
        relations.add(relation);
        checkLimit();
      }
    }

    /**
     * At the end of this function, all of the lists of unprocessed 'things'
     * must be null
     */
    private void switchTypes()
    {
      if(nodes != null) {
        groups.add(nodes);
        nodes = null;
      } else if(ways != null) {
        groups.add(ways);
        ways = null;
      } else if(relations != null) {
        groups.add(relations);
        relations = null;
      } else {
        return; // No data. Is this an empty file?
      }
    }

    /** Write empty header block when there's no bounds entity. */
    public void writeEmptyHeaderIfNeeded()
    {
      if(headerWritten) {
        return;
      }
      Osmformat.HeaderBlock.Builder headerblock = Osmformat.HeaderBlock
          .newBuilder();
      finishHeader(headerblock);
    }
  }

  public BinaryMapWriter(Area bounds, File outputDir, int mapId, int extra) {
    super(bounds, outputDir, mapId, extra);
  }

  public void initForWrite()
  {
    String filename = String.format(Locale.ROOT, "%08d.osm.pbf", mapId);
    try {
      output = new BlockOutputStream(new FileOutputStream(new File(outputDir,
          filename)));
      serializer = new PBFSerializer(output);
      writeHeader();
    }
    catch(IOException e) {
      System.out.println("Could not open or write file header. Reason: "
          + e.getMessage());
      throw new RuntimeException(e);
    }
  }

  private void writeHeader() throws IOException
  {
    Osmformat.HeaderBlock.Builder headerblock = Osmformat.HeaderBlock
        .newBuilder();

    Osmformat.HeaderBBox.Builder bbox = Osmformat.HeaderBBox.newBuilder();
    bbox.setLeft(serializer.mapRawDegrees(Utils.toDegrees(bounds.getMinLong())));
    bbox.setBottom(serializer.mapRawDegrees(Utils.toDegrees(bounds.getMinLat())));
    bbox.setRight(serializer.mapRawDegrees(Utils.toDegrees(bounds.getMaxLong())));
    bbox.setTop(serializer.mapRawDegrees(Utils.toDegrees(bounds.getMaxLat())));
    headerblock.setBbox(bbox);

    //    headerblock.setSource("splitter"); //TODO: entity.getOrigin());
    finishHeader(headerblock);
  }

  /** Write the header fields that are always needed.
   * 
   * @param headerblock Incomplete builder to complete and write.
   * */
  public void finishHeader(Osmformat.HeaderBlock.Builder headerblock)
  {
    headerblock.setWritingprogram("splitter-r171");
    headerblock.addRequiredFeatures("OsmSchema-V0.6");
    if(useDense) {
      headerblock.addRequiredFeatures("DenseNodes");
    }
    Osmformat.HeaderBlock message = headerblock.build();
    try {
      output.write(FileBlock.newInstance("OSMHeader", message.toByteString(),
          null));
    }
    catch(IOException e) {
      throw new RuntimeException("Unable to write OSM header.", e);
    }
    headerWritten = true;
  }

  public void finishWrite()
  {
    try {
		serializer.switchTypes();
		serializer.processBatch();
		serializer.close();
		serializer = null;
    }
    catch(IOException e) {
      System.out.println("Could not write end of file: " + e);
    }
  }

  public void write(Node node)
  {
    serializer.processor.process(node);
  }

  public void write(Way way)
  {
    serializer.processor.process(way);
  }

  public void write(Relation relation)
  {
    serializer.processor.process(relation);
  }
}
