#!/bin/sh

# ------------------------------------
# Function:
# - Builds Garmin plus maps.
#
# Version:
# - v1.0.0 - 2024/12/01: first release (kto)
# - v1.1.0 - 2024/12/07: region balkans added (kto)
# - v1.1.1 - 2024/12/14: licenses for contour lines for some maps fixed (kto)
#
# Remarks:
# - nohup sh mt-garmin-plus.sh >mt-garmin-plus.out 2>&1 &
# - Nachbarländer Deutschlands: Karten auch auf Deutsch
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
./mt.pl bootstrap

# fetch europe extract
./mt.pl create 8888
./mt.pl fetch_osm 8888

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
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6578
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6578
./mt.pl zip 6578

# Kingdom of Norway (NOR+NORTH)
./mt.pl --ram=24000 --cores=8 create 8110
./mt.pl --ram=24000 --cores=8 extract_osm 8110
./mt.pl --ram=24000 --cores=8 fetch_ele 8110
./mt.pl --ram=24000 --cores=8 join 8110
./mt.pl --ram=24000 --cores=8 split 8110
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 build 8110
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 8110
./mt.pl zip 8110

# Kingdom of Norway (NOR+SOUTH)
./mt.pl --ram=24000 --cores=8 create 8111
./mt.pl --ram=24000 --cores=8 extract_osm 8111
./mt.pl --ram=24000 --cores=8 fetch_ele 8111
./mt.pl --ram=24000 --cores=8 join 8111
./mt.pl --ram=24000 --cores=8 split 8111
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8111
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8111
./mt.pl zip 8111

# Kingdom of Sweden (SWE+)
./mt.pl --ram=24000 --cores=8 create 7752
./mt.pl --ram=24000 --cores=8 extract_osm 7752
./mt.pl --ram=24000 --cores=8 fetch_ele 7752
./mt.pl --ram=24000 --cores=8 join 7752
./mt.pl --ram=24000 --cores=8 split 7752
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7752
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7752
./mt.pl zip 7752

# Republic of Finland (FIN+)
./mt.pl --ram=24000 --cores=8 create 7246
./mt.pl --ram=24000 --cores=8 extract_osm 7246
./mt.pl --ram=24000 --cores=8 fetch_ele 7246
./mt.pl --ram=24000 --cores=8 join 7246
./mt.pl --ram=24000 --cores=8 split 7246
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 build 7246
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 7246
./mt.pl zip 7246

# Denmark (DNK+)
./mt.pl --ram=24000 --cores=8 create 7208
./mt.pl --ram=24000 --cores=8 extract_osm 7208
./mt.pl --ram=24000 --cores=8 fetch_ele 7208
./mt.pl --ram=24000 --cores=8 join 7208
./mt.pl --ram=24000 --cores=8 split 7208
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7208
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7208
./mt.pl zip 7208
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 7208
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 7208
./mt.pl --language=de zip 7208

# Iceland (ISL)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6352
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6352
./mt.pl zip 6352

# Faeroe Islands (FRO)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6234
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6234
./mt.pl zip 6234

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
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bim 9070
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 9070
./mt.pl zip 9070

# Russian Federation, Central Federal District (RUS_CENTRAL)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bim 9071
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 9071
./mt.pl zip 9071

# Russian Federation, Volga Federal District (RUS_VOLGA)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bim 9072
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 9072
./mt.pl zip 9072

# Russian Federation, Southern Federal District (RUS_SOUTH)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bim 9075
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 9075
./mt.pl zip 9075

# Russian Federation, Crimean Federal District (controversial under international law, RUS_CRIMEA)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 9073
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 9073
./mt.pl zip 9073

# Russian Federation, North Caucasian Federal District (RUS_NORTHCAUCASUS)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bim 9074
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_ALOS1} --demtype=1 bam 9074
./mt.pl zip 9074

# Russian Federation, Exclave Kaliningrad (RUS+KGD)
./mt.pl --ram=24000 --cores=8 create 8120
./mt.pl --ram=24000 --cores=8 extract_osm 8120
./mt.pl --ram=24000 --cores=8 fetch_ele 8120
./mt.pl --ram=24000 --cores=8 join 8120
./mt.pl --ram=24000 --cores=8 split 8120
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 8120
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 8120
./mt.pl zip 8120

# Republic of Belarus (BLR+)
./mt.pl --ram=24000 --cores=8 create 7112
./mt.pl --ram=24000 --cores=8 extract_osm 7112
./mt.pl --ram=24000 --cores=8 fetch_ele 7112
./mt.pl --ram=24000 --cores=8 join 7112
./mt.pl --ram=24000 --cores=8 split 7112
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7112
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7112
./mt.pl zip 7112

# Ukraine (UKR+)
./mt.pl --ram=24000 --cores=8 create 7804
./mt.pl --ram=24000 --cores=8 extract_osm 7804
./mt.pl --ram=24000 --cores=8 fetch_ele 7804
./mt.pl --ram=24000 --cores=8 join 7804
./mt.pl --ram=24000 --cores=8 split 7804
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7804
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7804
./mt.pl zip 7804

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
# Region Balkans (BALKAN)

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

# Region Balkans (BALKAN)
./mt.pl --ram=24000 --cores=8 create 8080
./mt.pl --ram=24000 --cores=8 extract_osm 8080
./mt.pl --ram=24000 --cores=8 fetch_ele 8080
./mt.pl --ram=24000 --cores=8 join 8080
./mt.pl --ram=24000 --cores=8 split 8080
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 8080
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 8080
./mt.pl zip 8080

# maps for 'Southern Europe'
# --------------------------
# Kingdom of Spain (ESP+)
# Portuguese Republic (PRT+)
# Italian Republic (ITA+)
# Republic of Malta (MLT)

# Kingdom of Spain (ESP+)
./mt.pl --ram=24000 --cores=8 create 7724
./mt.pl --ram=24000 --cores=8 extract_osm 7724
./mt.pl --ram=24000 --cores=8 fetch_ele 7724
./mt.pl --ram=24000 --cores=8 join 7724
./mt.pl --ram=24000 --cores=8 split 7724 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7724
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7724
./mt.pl zip 7724

# Portuguese Republic (PRT+)
./mt.pl --ram=24000 --cores=8 create 7620
./mt.pl --ram=24000 --cores=8 extract_osm 7620
./mt.pl --ram=24000 --cores=8 fetch_ele 7620
./mt.pl --ram=24000 --cores=8 join 7620
./mt.pl --ram=24000 --cores=8 split 7620 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7620
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7620
./mt.pl zip 7620
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7620
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7620
./mt.pl --language=en zip 7620

# Italian Republic (ITA+)
./mt.pl --ram=24000 --cores=8 create 7380
./mt.pl --ram=24000 --cores=8 extract_osm 7380 
./mt.pl --ram=24000 --cores=8 fetch_ele 7380 
./mt.pl --ram=24000 --cores=8 join 7380 
./mt.pl --ram=24000 --cores=8 split 7380 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7380 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7380
./mt.pl zip 7380
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7380
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7380
./mt.pl --language=en zip 7380

# Republic of Malta (MLT)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6470
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6470
./mt.pl zip 6470

# maps for 'Western Europe'
# -------------------------
# French Republic (FRA)
# French Republic (FRA+NORTHEAST)
# French Republic (FRA+NORTHWEST)
# French Republic (FRA+SOUTHEAST)
# French Republic (FRA+SOUTHWEST)
# Principality of Andorra (AND)
# Great Britain (GBR, Island)
# Isle of Man (IMN)
# Ireland (IRL, Island)
# Netherlands (NLD+)
# Kingdom of Belgium (BEL+)
# Region Belgium - Netherlands - Luxembourg (BEL_NLD_LUX)

# French Republic (FRA)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6250
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6250
./mt.pl zip 6250
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 6250
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 6250
./mt.pl --language=en zip 6250
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 6250
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 6250
./mt.pl --language=de zip 6250

# French Republic (FRA+NORTHWEST)
./mt.pl --ram=24000 --cores=8 create 8100
./mt.pl --ram=24000 --cores=8 extract_osm 8100 
./mt.pl --ram=24000 --cores=8 fetch_ele 8100
./mt.pl --ram=24000 --cores=8 join 8100
./mt.pl --ram=24000 --cores=8 split 8100 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8100
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8100
./mt.pl zip 8100

# French Republic (FRA+NORTHEAST)
./mt.pl --ram=24000 --cores=8 create 8101
./mt.pl --ram=24000 --cores=8 extract_osm 8101 
./mt.pl --ram=24000 --cores=8 fetch_ele 8101
./mt.pl --ram=24000 --cores=8 join 8101
./mt.pl --ram=24000 --cores=8 split 8101 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8101
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8101
./mt.pl zip 8101

# French Republic (FRA+SOUTHWEST)
./mt.pl --ram=24000 --cores=8 create 8102
./mt.pl --ram=24000 --cores=8 extract_osm 8102 
./mt.pl --ram=24000 --cores=8 fetch_ele 8102
./mt.pl --ram=24000 --cores=8 join 8102
./mt.pl --ram=24000 --cores=8 split 8102 
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8102
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8102
./mt.pl zip 8102

# French Republic (FRA+SOUTHEAST)
./mt.pl --ram=24000 --cores=8 create 8103
./mt.pl --ram=24000 --cores=8 extract_osm 8103
./mt.pl --ram=24000 --cores=8 fetch_ele 8103
./mt.pl --ram=24000 --cores=8 join 8103
./mt.pl --ram=24000 --cores=8 split 8103
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8103
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8103
./mt.pl zip 8103

# Principality of Andorra (AND)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6020
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6020
./mt.pl zip 6020

# Great Britain (GBR, Island)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6826
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6826
./mt.pl zip 6826

# Isle of Man (IMN)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6833
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6833
./mt.pl zip 6833

# Ireland (IRL, Island)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6372
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6372
./mt.pl zip 6372

# Netherlands (NLD+)
./mt.pl --ram=24000 --cores=8 create 7528
./mt.pl --ram=24000 --cores=8 extract_osm 7528
./mt.pl --ram=24000 --cores=8 fetch_ele 7528
./mt.pl --ram=24000 --cores=8 join 7528
./mt.pl --ram=24000 --cores=8 split 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7528
./mt.pl zip 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7528
./mt.pl --language=en zip 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 7528
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 7528
./mt.pl --language=de zip 7528

# Kingdom of Belgium (BEL+)
./mt.pl --ram=24000 --cores=8 create 7056
./mt.pl --ram=24000 --cores=8 extract_osm 7056
./mt.pl --ram=24000 --cores=8 fetch_ele 7056
./mt.pl --ram=24000 --cores=8 join 7056
./mt.pl --ram=24000 --cores=8 split 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7056
./mt.pl zip 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=fr build 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=fr bam 7056
./mt.pl --language=fr zip 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=nl build 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=nl bam 7056
./mt.pl --language=nl zip 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 7056
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 7056
./mt.pl --language=de zip 7056

# Region Belgium - Netherlands - Luxembourg (BEL_NLD_LUX)
./mt.pl --ram=24000 --cores=8 create 8040
./mt.pl --ram=24000 --cores=8 extract_osm 8040
./mt.pl --ram=24000 --cores=8 fetch_ele 8040
./mt.pl --ram=24000 --cores=8 join 8040
./mt.pl --ram=24000 --cores=8 split 8040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8040
./mt.pl zip 8040

# maps for 'Middle Europe'
# ------------------------
# Federal Republic of Germany (DEU+NORTH)
# Federal Republic of Germany (DEU+SOUTH)
# Federal Republic of Germany (DEU)
# Republic of Austria (AUT+)
# Swiss Confederation (CHE+)
# Grand Duchy of Luxembourg (LUX+)
# Republic of Croatia (HRV+)
# Republic of Poland (POL+)
# Republic of Lithuania (LTU+)
# Republic of Latvia (LVA+)
# Republic of Estonia (EST+)
# Czech Republic (CZE+)
# Slovak Republic (SVK+)
# Republic of Slovenia (SVN+)
# Hungary (HUN+)

# Federal Republic of Germany (DEU+NORTH)
./mt.pl --ram=24000 --cores=8 create 8090
./mt.pl --ram=24000 --cores=8 extract_osm 8090
./mt.pl --ram=24000 --cores=8 fetch_ele 8090
./mt.pl --ram=24000 --cores=8 join 8090
./mt.pl --ram=24000 --cores=8 split 8090
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8090
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8090
./mt.pl zip 8090

# Federal Republic of Germany (DEU+SOUTH)
./mt.pl --ram=24000 --cores=8 create 8091
./mt.pl --ram=24000 --cores=8 extract_osm 8091
./mt.pl --ram=24000 --cores=8 fetch_ele 8091
./mt.pl --ram=24000 --cores=8 join 8091
./mt.pl --ram=24000 --cores=8 split 8091
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8091
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8091
./mt.pl zip 8091

# Federal Republic of Germany (DEU)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 6276
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 6276
./mt.pl zip 6276
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 6276
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 6276
./mt.pl --language=en zip 6276

# Republic of Austria (AUT+)
./mt.pl --ram=24000 --cores=8 create 7040
./mt.pl --ram=24000 --cores=8 extract_osm 7040
./mt.pl --ram=24000 --cores=8 fetch_ele 7040
./mt.pl --ram=24000 --cores=8 join 7040
./mt.pl --ram=24000 --cores=8 split 7040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7040
./mt.pl zip 7040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7040
./mt.pl --language=en zip 7040

# Swiss Confederation (CHE+)
./mt.pl --ram=24000 --cores=8 create 7756
./mt.pl --ram=24000 --cores=8 extract_osm 7756
./mt.pl --ram=24000 --cores=8 fetch_ele 7756
./mt.pl --ram=24000 --cores=8 join 7756
./mt.pl --ram=24000 --cores=8 split 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7756
./mt.pl zip 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7756
./mt.pl --language=en zip 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=fr build 7756
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=fr bam 7756
./mt.pl --language=fr zip 7756

# Grand Duchy of Luxembourg (LUX+)
./mt.pl --ram=24000 --cores=8 create 7442
./mt.pl --ram=24000 --cores=8 extract_osm 7442
./mt.pl --ram=24000 --cores=8 fetch_ele 7442
./mt.pl --ram=24000 --cores=8 join 7442
./mt.pl --ram=24000 --cores=8 split 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7442
./mt.pl zip 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 7442
./mt.pl --language=en zip 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 7442
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 7442
./mt.pl --language=de zip 7442

# Republic of Croatia (HRV+)
./mt.pl --ram=24000 --cores=8 create 7191
./mt.pl --ram=24000 --cores=8 extract_osm 7191
./mt.pl --ram=24000 --cores=8 fetch_ele 7191
./mt.pl --ram=24000 --cores=8 join 7191
./mt.pl --ram=24000 --cores=8 split 7191
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7191
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7191
./mt.pl zip 7191

# Republic of Poland (POL+)
./mt.pl --ram=24000 --cores=8 create 7616
./mt.pl --ram=24000 --cores=8 extract_osm 7616
./mt.pl --ram=24000 --cores=8 fetch_ele 7616
./mt.pl --ram=24000 --cores=8 join 7616
./mt.pl --ram=24000 --cores=8 split 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7616
./mt.pl zip 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 --language=en build 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 --language=en bam 7616
./mt.pl --language=en zip 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 --language=de build 7616
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 --language=de bam 7616
./mt.pl --language=de zip 7616

# Republic of Lithuania (LTU+)
./mt.pl --ram=24000 --cores=8 create 7440
./mt.pl --ram=24000 --cores=8 extract_osm 7440
./mt.pl --ram=24000 --cores=8 fetch_ele 7440
./mt.pl --ram=24000 --cores=8 join 7440
./mt.pl --ram=24000 --cores=8 split 7440
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7440
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7440
./mt.pl zip 7440

# Republic of Latvia (LVA+)
./mt.pl --ram=24000 --cores=8 create 7428
./mt.pl --ram=24000 --cores=8 extract_osm 7428
./mt.pl --ram=24000 --cores=8 fetch_ele 7428
./mt.pl --ram=24000 --cores=8 join 7428
./mt.pl --ram=24000 --cores=8 split 7428
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7428
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7428
./mt.pl zip 7428

# Republic of Estonia (EST+)
./mt.pl --ram=24000 --cores=8 create 7233
./mt.pl --ram=24000 --cores=8 extract_osm 7233
./mt.pl --ram=24000 --cores=8 fetch_ele 7233
./mt.pl --ram=24000 --cores=8 join 7233
./mt.pl --ram=24000 --cores=8 split 7233
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7233
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7233
./mt.pl zip 7233

# Czech Republic (CZE+)
./mt.pl --ram=24000 --cores=8 create 7203
./mt.pl --ram=24000 --cores=8 extract_osm 7203
./mt.pl --ram=24000 --cores=8 fetch_ele 7203
./mt.pl --ram=24000 --cores=8 join 7203
./mt.pl --ram=24000 --cores=8 split 7203
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7203
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7203
./mt.pl zip 7203
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 7203
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 7203
./mt.pl --language=de zip 7203

# Slovak Republic (SVK+)
./mt.pl --ram=24000 --cores=8 create 7703
./mt.pl --ram=24000 --cores=8 extract_osm 7703
./mt.pl --ram=24000 --cores=8 fetch_ele 7703
./mt.pl --ram=24000 --cores=8 join 7703
./mt.pl --ram=24000 --cores=8 split 7703
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7703
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7703
./mt.pl zip 7703

# Republic of Slovenia (SVN+)
./mt.pl --ram=24000 --cores=8 create 7705
./mt.pl --ram=24000 --cores=8 extract_osm 7705
./mt.pl --ram=24000 --cores=8 fetch_ele 7705
./mt.pl --ram=24000 --cores=8 join 7705
./mt.pl --ram=24000 --cores=8 split 7705
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 7705
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 7705
./mt.pl zip 7705

# Hungary (HUN+)
./mt.pl --ram=24000 --cores=8 create 7348
./mt.pl --ram=24000 --cores=8 extract_osm 7348
./mt.pl --ram=24000 --cores=8 fetch_ele 7348
./mt.pl --ram=24000 --cores=8 join 7348
./mt.pl --ram=24000 --cores=8 split 7348
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 build 7348
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 7348
./mt.pl zip 7348

# maps for 'Mountains'
# --------------------
# Western Alps (ALPS_WEST)
# Eastern Alps (ALPS_EAST)
# Carpathians (CARPATHIAN)
# Pyrenees (PYRENEES)

# Western Alps (ALPS_WEST)
./mt.pl --ram=24000 --cores=8 --language=de create 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de extract_osm 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de fetch_ele 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de join 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de split 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 8021 DTRIGMARK DT36ROUTING
./mt.pl --language=de zip 8021
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 8021 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 8021 DTRIGMARK DT36ROUTING
./mt.pl --language=en zip 8021

# Eastern Alps (ALPS_EAST)
./mt.pl --ram=24000 --cores=8 --language=de create 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de extract_osm 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de fetch_ele 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de join 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=de split 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de build 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=de bam 8022 DTRIGMARK DT36ROUTING
./mt.pl --language=de zip 8022
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 8022 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 8022 DTRIGMARK DT36ROUTING
./mt.pl --language=en zip 8022

# Carpathians (CARPATHIAN)
./mt.pl --ram=24000 --cores=8 --language=en create 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en extract_osm 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en fetch_ele 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en join 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en split 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en --dempath=${DEM_SRTM1} --demtype=1 build 8070 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en --dempath=${DEM_SRTM1} --demtype=1 bam 8070 DTRIGMARK DT36ROUTING
./mt.pl --language=en zip 8070

# Pyrenees (PYRENEES)
./mt.pl --ram=24000 --cores=8 --language=en create 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en extract_osm 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en fetch_ele 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en join 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en split 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en --dempath=${DEM_SONN1} --demtype=1 build 8060 DT36ROUTING DTRIGMARK
./mt.pl --ram=24000 --cores=8 --language=en --dempath=${DEM_SONN1} --demtype=1 bam 8060 DTRIGMARK DT36ROUTING
./mt.pl --language=en zip 8060

# maps for 'Other Countries'
# --------------------------
# Balearics (BALEARICS)
# Azores (AZORES)
# Madeira (MADEIRA)
# Canarias (ESP_CANARIAS)
# Republic of Türkiye (TUR)

# Balearics (BALEARICS)
./mt.pl --ram=24000 --cores=8 create 8130
./mt.pl --ram=24000 --cores=8 extract_osm 8130
./mt.pl --ram=24000 --cores=8 fetch_ele 8130
./mt.pl --ram=24000 --cores=8 join 8130
./mt.pl --ram=24000 --cores=8 split 8130
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8130
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8130
./mt.pl zip 8130

# Azores (AZORES)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 9040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 9040
./mt.pl zip 9040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bim 9040
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 9040
./mt.pl --language=en zip 9040

# Madeira (MADEIRA)
./mt.pl --ram=24000 --cores=8 create 8131
./mt.pl --ram=24000 --cores=8 extract_osm 8131
./mt.pl --ram=24000 --cores=8 fetch_ele 8131
./mt.pl --ram=24000 --cores=8 join 8131
./mt.pl --ram=24000 --cores=8 split 8131
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 build 8131
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 8131
./mt.pl zip 8131
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en build 8131
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 --language=en bam 8131
./mt.pl --language=en zip 8131

# Canarias (ESP_CANARIAS)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bim 9020
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SONN1} --demtype=1 bam 9020
./mt.pl zip 9020

# Republic of Türkiye (TUR)
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bim 6792
./mt.pl --ram=24000 --cores=8 --dempath=${DEM_SRTM1} --demtype=1 bam 6792
./mt.pl zip 6792

# Typ files
# ---------
./mt.pl alltypfiles
./mt.pl replacetyp

# stop time
date
