package uk.me.parabola.splitter;

import crosby.binary.BinaryParser;
import crosby.binary.Osmformat;
import crosby.binary.file.FileBlockPosition;


import it.unimi.dsi.fastutil.shorts.ShortArrayList;

import java.util.List;

public class BinaryMapParser extends BinaryParser implements MapReader {
	private static final short TYPE_DENSE = 0x1; 
	private static final short TYPE_NODES = 0x2; 
	private static final short TYPE_WAYS = 0x4; 
	private static final short TYPE_RELS = 0x8; 
	private final ShortArrayList blockTypes = new ShortArrayList();
	private final ShortArrayList knownBlockTypes;

	// for status messages
	private final ElementCounter elemCounter = new ElementCounter();
	
	private short blockType = -1;
	private int blockCount = -1;
	private boolean skipTags;
	private boolean skipNodes;
	private boolean skipWays;
	private boolean skipRels;
	short wantedTypeMask = 0;
	
	BinaryMapParser(MapProcessor processor, ShortArrayList knownBlockTypes) {
		this.processor = processor;
		this.knownBlockTypes = knownBlockTypes;
		this.skipTags = processor.skipTags();
		this.skipNodes = processor.skipNodes();
		this.skipWays = processor.skipWays();
		this.skipRels = processor.skipRels();
		
		if (skipNodes == false){
			wantedTypeMask |= TYPE_DENSE;
			wantedTypeMask |= TYPE_NODES;
		}
		if (skipWays == false)
			wantedTypeMask |= TYPE_WAYS;
		if (skipRels == false)
			wantedTypeMask |= TYPE_RELS;
	}
	MapProcessor processor;

	public ShortArrayList getBlockList(){
		return blockTypes;
	}
	
	@Override
    public boolean skipBlock(FileBlockPosition block) {
		blockCount++;
		if (knownBlockTypes != null){
			blockType = knownBlockTypes.getShort(blockCount);
			if (blockType != 0 && (blockType & wantedTypeMask) == 0)
				return true;
		}
		else if (blockType != -1){
			//System.out.println("previous block contained " + blockType );
			blockTypes.add(blockType);
		}
		blockType = 0;
        // System.out.println("Seeing block of type: "+block.getType());
        if (block.getType().equals("OSMData"))
            return false;
        if (block.getType().equals("OSMHeader"))
            return false;
        System.out.println("Skipped block of type: " + block.getType());
        return true;
    }
	
	@Override
	public void complete() {
		blockTypes.add(blockType);
		// End of map is sent when all input files are processed.
		// So do nothing else.
	}

	// Per-block state for parsing, set when processing the header of a block;
	@Override
	protected void parseDense(Osmformat.DenseNodes nodes) {
		blockType |= TYPE_DENSE;
		if (skipNodes)
			return;
		long last_id = 0, last_lat = 0, last_lon = 0;
		int j = 0;
		int maxi = nodes.getIdCount();
		Node tmp = new Node();
		for (int i=0 ; i < maxi; i++) {
			long lat = nodes.getLat(i)+last_lat; last_lat = lat;
			long lon = nodes.getLon(i)+last_lon; last_lon = lon;
			long id =  nodes.getId(i)+last_id; last_id = id;
			double latf = parseLat(lat), lonf = parseLon(lon);

			tmp = new Node();
			tmp.set(id, latf, lonf);

			if (!skipTags) {
				if (nodes.getKeysValsCount() > 0) {
					while (nodes.getKeysVals(j) != 0) {
						int keyid = nodes.getKeysVals(j++);
						int valid = nodes.getKeysVals(j++);
						tmp.addTag(getStringById(keyid),getStringById(valid));
					}
					j++; // Skip over the '0' delimiter.

				}
			}
			processor.processNode(tmp);
			elemCounter.countNode(tmp.getId());
		}
	}

	@Override
	protected void parseNodes(List<Osmformat.Node> nodes) {
		if (nodes.size() == 0) 
			return;
		blockType |= TYPE_NODES;
		if (skipNodes) 
			return;
		for (Osmformat.Node i : nodes) {
			Node tmp = new Node();
			for (int j=0 ; j < i.getKeysCount(); j++)
				tmp.addTag(getStringById(i.getKeys(j)),getStringById(i.getVals(j)));
			long id = i.getId();
			double latf = parseLat(i.getLat()), lonf = parseLon(i.getLon());

			tmp.set(id, latf, lonf);

			processor.processNode(tmp);
			elemCounter.countNode(tmp.getId());
		}
	}


	@Override
	protected void parseWays(List<Osmformat.Way> ways) {
		long numways = ways.size();
		if (numways == 0) 
			return;
		blockType |= TYPE_WAYS;
		if (skipWays) 
			return;
		for (Osmformat.Way i : ways) {
			Way tmp = new Way();
			if (skipTags == false){
				for (int j=0 ; j < i.getKeysCount(); j++)
					tmp.addTag(getStringById(i.getKeys(j)),getStringById(i.getVals(j)));
			}
			long last_id=0;
			for (long j : i.getRefsList()) {
				tmp.addRef(j+last_id);
				last_id = j+last_id;
			}

			long id = i.getId();
			tmp.setId(id);

			processor.processWay(tmp);
			elemCounter.countWay(i.getId());
		}
	}



	@Override
	protected void parseRelations(List<Osmformat.Relation> rels) {
		if (rels.size() == 0) 
			return;
		blockType |= TYPE_RELS;
		if (skipRels)
			return;
		for (Osmformat.Relation i : rels) {
			Relation tmp = new Relation();
			if (skipTags == false){
				for (int j=0 ; j < i.getKeysCount(); j++)
					tmp.addTag(getStringById(i.getKeys(j)),getStringById(i.getVals(j)));
			}
			long id = i.getId();
			tmp.setId(id);

			long last_mid=0;
			for (int j =0; j < i.getMemidsCount() ; j++) {
				long mid = last_mid + i.getMemids(j);
				last_mid = mid;
				String role = getStringById(i.getRolesSid(j));
				String etype=null;

				if (i.getTypes(j) == Osmformat.Relation.MemberType.NODE)
					etype = "node";
				else if (i.getTypes(j) == Osmformat.Relation.MemberType.WAY)
					etype = "way";
				else if (i.getTypes(j) == Osmformat.Relation.MemberType.RELATION)
					etype = "relation";
				else
					assert false; // TODO; Illegal file?

				tmp.addMember(etype,mid,role);
			}
			processor.processRelation(tmp);
			elemCounter.countRelation(tmp.getId());
		}
	}

	@Override
	public void parse(Osmformat.HeaderBlock block) {

		for (String s : block.getRequiredFeaturesList()) {
			if (s.equals("OsmSchema-V0.6")) continue; // OK.
			if (s.equals("DenseNodes")) continue; // OK.
			throw new UnknownFeatureException(s);
		}

		if (block.hasBbox()) {
			final double multiplier = .000000001;
			double rightf = block.getBbox().getRight() * multiplier;
			double leftf = block.getBbox().getLeft() * multiplier;
			double topf = block.getBbox().getTop() * multiplier;
			double bottomf = block.getBbox().getBottom() * multiplier;

			System.out.println("Bounding box "+leftf+" "+bottomf+" "+rightf+" "+topf);

			Area area = new Area(
					Utils.toMapUnit(bottomf),
					Utils.toMapUnit(leftf),
					Utils.toMapUnit(topf),
					Utils.toMapUnit(rightf));
			processor.boundTag(area);
		}
	}
}
