#!/bin/sh

# ------------------------------------
# Function:
# - Builds Garmin plus maps.
#
# Version:
# - v1.0.0 - 2024/11/25: first release (kto)
#
# Remarks:
# - nohup sh mt-garmin-plus.sh >mt-garmin-plus.out 2>&1 &
# ------------------------------------

# verbose mode
set -o verbose

# start time
date

# change working directory
cd Freizeitkarte-Entwicklung

# define DEM paths
DEM_SONN1=/data/dem/hgt/SONN1
DEM_SRTM1=/data/dem/hgt/SRTM1v3.0.hgt
DEM_ALOS1=/data/dem/hgt/ALOS1.hgt

# fetch boundaries and sea boundaries
# ./mt.pl bootstrap

# fetch europe extract
# ./mt.pl create 8888
# ./mt.pl fetch_osm 8888

# maps for 'Northern Europe'
# --------------------------
# Kingdom of Norway (NOR)
# Kingdom of Norway (NOR+NORTH)
# Kingdom of Norway (NOR+SOUTH)
# Kingdom of Sweden (SWE+)
# Republic of Finland (FIN+)
# Denmark (DNK+)
# Iceland (ISL)
# Faeroe Islands (FRO)

# Kingdom of Norway (NOR)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6578
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6578
# ./mt.pl zip 6578

# Kingdom of Norway (NOR+NORTH)
# ./mt.pl --ram=24000 --cores=8 create 8110
# ./mt.pl --ram=24000 --cores=8 extract_osm 8110
# ./mt.pl --ram=24000 --cores=8 fetch_ele 8110
# ./mt.pl --ram=24000 --cores=8 join 8110
# ./mt.pl --ram=24000 --cores=8 split 8110
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8110
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8110
# ./mt.pl zip 8110

# Kingdom of Norway (NOR+SOUTH)
# ./mt.pl --ram=24000 --cores=8 create 8111
# ./mt.pl --ram=24000 --cores=8 extract_osm 8111
# ./mt.pl --ram=24000 --cores=8 fetch_ele 8111
# ./mt.pl --ram=24000 --cores=8 join 8111
# ./mt.pl --ram=24000 --cores=8 split 8111
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8111
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8111
# ./mt.pl zip 8111

# Kingdom of Sweden (SWE+)
# ./mt.pl --ram=24000 --cores=8 create 7752
# ./mt.pl --ram=24000 --cores=8 extract_osm 7752
# ./mt.pl --ram=24000 --cores=8 fetch_ele 7752
# ./mt.pl --ram=24000 --cores=8 join 7752
# ./mt.pl --ram=24000 --cores=8 split 7752
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7752
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7752
# ./mt.pl zip 7752

# Republic of Finland (FIN+)
# ./mt.pl --ram=24000 --cores=8 create 7246
# ./mt.pl --ram=24000 --cores=8 extract_osm 7246
# ./mt.pl --ram=24000 --cores=8 fetch_ele 7246
# ./mt.pl --ram=24000 --cores=8 join 7246
# ./mt.pl --ram=24000 --cores=8 split 7246
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7246
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7246
# ./mt.pl zip 7246

# Denmark (DNK+)
# ./mt.pl --ram=24000 --cores=8 create 7208
# ./mt.pl --ram=24000 --cores=8 extract_osm 7208
# ./mt.pl --ram=24000 --cores=8 fetch_ele 7208
# ./mt.pl --ram=24000 --cores=8 join 7208
# ./mt.pl --ram=24000 --cores=8 split 7208
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7208
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7208
# ./mt.pl zip 7208

# Iceland (ISL)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6352
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6352
# ./mt.pl zip 6352

# Faeroe Islands (FRO)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6234
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6234
# ./mt.pl zip 6234

# maps for 'Eastern Europe'
# -------------------------
# Russian Federation, Northwestern Federal District (RUS_NORTHWEST)
# Russian Federation, Central Federal District (RUS_CENTRAL)
# Russian Federation, Volga Federal District (RUS_VOLGA)
# Russian Federation, Southern Federal District (RUS_SOUTH)
# Russian Federation, Crimean Federal District (controversial under international law, RUS_CRIMEA)
# Russian Federation, North Caucasian Federal District (RUS_NORTHCAUCASUS)
# Russian Federation, Exclave Kaliningrad (RUS+KGD)
# Republic of Belarus (BLR+)
# Ukraine (UKR+)

# Russian Federation, Northwestern Federal District (RUS_NORTHWEST)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9070
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9070
# ./mt.pl zip 9070

# Russian Federation, Central Federal District (RUS_CENTRAL)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9071
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9071
# ./mt.pl zip 9071

# Russian Federation, Volga Federal District (RUS_VOLGA)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9072
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9072
# ./mt.pl zip 9072

# Russian Federation, Southern Federal District (RUS_SOUTH)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9075
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9075
# ./mt.pl zip 9075

# Russian Federation, Crimean Federal District (controversial under international law, RUS_CRIMEA)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9073
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9073
# ./mt.pl zip 9073

# Russian Federation, North Caucasian Federal District (RUS_NORTHCAUCASUS)
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9074
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9074
# ./mt.pl zip 9074

# Russian Federation, Exclave Kaliningrad (RUS+KGD)
# ./mt.pl --ram=24000 --cores=8 create 8120
# ./mt.pl --ram=24000 --cores=8 extract_osm 8120
# ./mt.pl --ram=24000 --cores=8 fetch_ele 8120
# ./mt.pl --ram=24000 --cores=8 join 8120
# ./mt.pl --ram=24000 --cores=8 split 8120
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 8120
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 8120
# ./mt.pl zip 8120

# Republic of Belarus (BLR+)
# ./mt.pl --ram=24000 --cores=8 create 7112
# ./mt.pl --ram=24000 --cores=8 extract_osm 7112
# ./mt.pl --ram=24000 --cores=8 fetch_ele 7112
# ./mt.pl --ram=24000 --cores=8 join 7112
# ./mt.pl --ram=24000 --cores=8 split 7112
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7112
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7112
# ./mt.pl zip 7112

# Ukraine (UKR+)
# ./mt.pl --ram=24000 --cores=8 create 7804
# ./mt.pl --ram=24000 --cores=8 extract_osm 7804
# ./mt.pl --ram=24000 --cores=8 fetch_ele 7804
# ./mt.pl --ram=24000 --cores=8 join 7804
# ./mt.pl --ram=24000 --cores=8 split 7804
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7804
# ./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7804
# ./mt.pl zip 7804

# maps for 'South Eastern Europe'
# -------------------------------
# Hellenic Republic (GRC+, Greece)
# Republic of Albania (ALB+)
# Republic of Bulgaria (BGR+)
# Cyprus (CYP, Island)
# Romania (ROU+)
# Republic of North Macedonia (MKD+)
# Republic of Moldova (MDA+)
# Republic of Serbia (SRB+)
# Republic of Bosnia and Herzegovina (BIH+)
# Republic of Kosovo (controversial under international law, see Republic of Serbia)
# Montenegro (MNE+)

# Hellenic Republic (GRC+, Greece)
./mt.pl --ram=24000 --cores=8 create 7300
./mt.pl --ram=24000 --cores=8 extract_osm 7300
./mt.pl --ram=24000 --cores=8 fetch_ele 7300
./mt.pl --ram=24000 --cores=8 join 7300
./mt.pl --ram=24000 --cores=8 split 7300
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7300
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7300
./mt.pl zip 7300

# Republic of Albania (ALB+)
./mt.pl --ram=24000 --cores=8 create 7008
./mt.pl --ram=24000 --cores=8 extract_osm 7008
./mt.pl --ram=24000 --cores=8 fetch_ele 7008
./mt.pl --ram=24000 --cores=8 join 7008
./mt.pl --ram=24000 --cores=8 split 7008
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7008
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7008
./mt.pl zip 7008

# Republic of Bulgaria (BGR+)
./mt.pl --ram=24000 --cores=8 create 7100
./mt.pl --ram=24000 --cores=8 extract_osm 7100
./mt.pl --ram=24000 --cores=8 fetch_ele 7100
./mt.pl --ram=24000 --cores=8 join 7100
./mt.pl --ram=24000 --cores=8 split 7100
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7100
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7100
./mt.pl zip 7100

# Cyprus (CYP, Island)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 6196
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 6196
./mt.pl zip 6196

# Romania (ROU+)
./mt.pl --ram=24000 --cores=8 create 7642
./mt.pl --ram=24000 --cores=8 extract_osm 7642
./mt.pl --ram=24000 --cores=8 fetch_ele 7642
./mt.pl --ram=24000 --cores=8 join 7642
./mt.pl --ram=24000 --cores=8 split 7642
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7642
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7642
./mt.pl zip 7642

# Republic of North Macedonia (MKD+)
./mt.pl --ram=24000 --cores=8 create 7807
./mt.pl --ram=24000 --cores=8 extract_osm 7807
./mt.pl --ram=24000 --cores=8 fetch_ele 7807
./mt.pl --ram=24000 --cores=8 join 7807
./mt.pl --ram=24000 --cores=8 split 7807
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7807
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7807
./mt.pl zip 7807

# Republic of Moldova (MDA+)
./mt.pl --ram=24000 --cores=8 create 7498
./mt.pl --ram=24000 --cores=8 extract_osm 7498
./mt.pl --ram=24000 --cores=8 fetch_ele 7498
./mt.pl --ram=24000 --cores=8 join 7498
./mt.pl --ram=24000 --cores=8 split 7498
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7498
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7498
./mt.pl zip 7498

# Republic of Serbia (SRB+)
./mt.pl --ram=24000 --cores=8 create 7688
./mt.pl --ram=24000 --cores=8 extract_osm 7688
./mt.pl --ram=24000 --cores=8 fetch_ele 7688
./mt.pl --ram=24000 --cores=8 join 7688
./mt.pl --ram=24000 --cores=8 split 7688
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7688
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7688
./mt.pl zip 7688

# Republic of Bosnia and Herzegovina (BIH+)
./mt.pl --ram=24000 --cores=8 create 7070
./mt.pl --ram=24000 --cores=8 extract_osm 7070
./mt.pl --ram=24000 --cores=8 fetch_ele 7070
./mt.pl --ram=24000 --cores=8 join 7070
./mt.pl --ram=24000 --cores=8 split 7070
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7070
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7070
./mt.pl zip 7070

# Republic of Kosovo (controversial under international law, see Republic of Serbia)
# TODO

# Montenegro (MNE+)
./mt.pl --ram=24000 --cores=8 create 7499
./mt.pl --ram=24000 --cores=8 extract_osm 7499
./mt.pl --ram=24000 --cores=8 fetch_ele 7499
./mt.pl --ram=24000 --cores=8 join 7499
./mt.pl --ram=24000 --cores=8 split 7499
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7499
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7499
./mt.pl zip 7499


# ./mt.pl alltypfiles
# ./mt.pl replacetyp

# stop time
date
