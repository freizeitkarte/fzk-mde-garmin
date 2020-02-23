#!/usr/bin/perl
# ---------------------------------------
# Program : mt.pl (map tool)
# Version : siehe unten
#
# Copyright (C) 2011-2013 Klaus Tockloth <Klaus.Tockloth@googlemail.com>
#               2013-2015 Adaptions by Patrik Brunner <keenonkites@gmx.net>
# - modified for Ubuntu through GVE
#
# Programmcode formatiert mit "perltidy".
# ---------------------------------------

use strict;
use warnings;
use English '-no_match_vars';

use Cwd;
use Cwd 'abs_path';
use File::Copy;
use File::Copy "cp";
use File::Find;
use File::Path;
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use POSIX qw(uname setlocale locale_h LC_ALL LC_CTYPE);
use Encode qw(is_utf8 decode encode );

my @actions = (
  # Normal User Actions for maps
  # (This actions should not be deleted/changed)
  # 'Action',    'Description',                                                       'show in help', 'langdir ?', 'target map types'
  [ 'bootstrap', '    Complete the Environment with needed downloads (boundaries)' ,  '-' ,           'no',        '0'   ],
  [ 'create',    '1.  (re)create all directories' ,                                   '-' ,           'no',        '123' ],
  [ 'fetch_osm', '2a. fetch osm data from url' ,                                      '-' ,           'no',        '123' ],
  [ 'fetch_ele', '2b. fetch elevation data from url' ,                                '-' ,           'no',        '23'  ],
  [ 'join',      '3.  join osm and elevation data' ,                                  '-' ,           'no',        '23'  ],
  [ 'split',     '4.  split map data into tiles' ,                                    '-' ,           'no',        '23'  ],
  [ 'build',     '5.  build map files (img, mdx, tdb)' ,                              '-' ,           'yes',       '23'  ],
  [ 'gmap',      '6.  create gmap file (for BaseCamp OS X, Windows)' ,                '-' ,           'yes',       '23'  ],
  [ 'nsis',      '6.  create nsis installer (full installer for Windows)' ,           '-' ,           'yes',       '23'  ],
  [ 'gmapsupp',  '6.  create gmapsupp image (for GPS receiver)' ,                     '-' ,           'yes',       '23'  ],
  [ 'imagedir',  '6.  create image directory (e.g. for QLandkarte)' ,                 '-' ,           'yes',       '23'  ],

  # Optional Actions for maps (Hidden from normal users) 
  # (This might change without notification)
  # 'Action',    'Description',                                                       'show in help', 'langdir ?', 'target map types'
  [ 'cfg',        'A. create individual cfg file' ,                                   'optional' ,    'yes' ,      '23' ],
  [ 'typ',        'B. create individual typ file from master' ,                       'optional' ,    'yes' ,      '23' ],
  [ 'compiletyp', 'B. compile TYP files out of text files' ,                          'optional' ,    'yes' ,      '23' ],
  [ 'nsisgmap',   'C. create nsis installer (GMAP for BaseCamp Windows)' ,            'optional' ,    'yes' ,      '23' ],
  [ 'gmap2',      'D. create gmap file - gmapi-builder (for BaseCamp OS X, Windows)', 'optional' ,    'yes' ,      '23' ],
  [ 'gmap3',      'D. create gmap file - jmc_cli (for BaseCamp OS X, Windows)' ,      'optional' ,    'yes' ,      '23' ],
  [ 'bim',        'E1.build images: create, fetch_*, join, split, build' ,            'optional' ,    'yes' ,      '23' ],
  [ 'bam',        'E2.build all maps: gmap, nsis, gmapsupp, imagedir' ,               'optional' ,    'yes' ,      '23' ],
  [ 'pmd',        'F1.Prepare Map Data: create, fetch_*, join, split' ,               'optional' ,    'no' ,       '23' ],
  [ 'bml',        'F2.Build Map Language: build, gmap, nsis, gmapsupp, imagedir' ,    'optional' ,    'yes' ,      '23' ],
  [ 'zip',        'G. zip all maps' ,                                                 'optional' ,    'yes' ,      '23' ],
  [ 'regions',    'H. extract all needed maps from big region data',                  'optional' ,    'no' ,       '1' ],
  [ 'extract_osm','I. extract single map from big region data' ,                      'optional' ,    'no' ,       '2' ],
  [ 'alltypfiles','J. Create all languages of the TYP files' ,                        'optional' ,    'no' ,       '0' ],
  [ 'replacetyp', 'K. Create all language versions of ReplaceTyp.zip' ,               'optional' ,    'no' ,       '0' ],
  [ 'check_osmid','L. Check overlapping OSM ID ranges for map and ele',               'optional' ,    'no' ,       '23' ],
  #[ 'fetch_map',  'J. fetch map data from Europe directory' ,                         'optional' ,    'no' ,       '2' ],

  # Hidden Actions not related to maps 
  # (This might change without notification)
  # 'Action',    'Description',                                                       'show in help', 'langdir ?', 'target map types'
  [ 'checkurl',   '   Check all download URLs for existence' ,                        'optional' ,    'no' ,       '0' ],
  [ 'fingerprint','   Show the versions of the different tools' ,                     'optional' ,    'no' ,       '0' ],
);

my @supportedlanguages = (
  # 'code', 'Beschreibung'
  # Iso639-1
  [ 'de', 'Deutsch' ],
  [ 'en', 'English' ],
  [ 'fr', 'French' ],
  [ 'it', 'Italian' ],
  [ 'nl', 'Dutch' ],
  [ 'pl', 'Polish' ],
  [ 'pt', 'Portuguese' ],
  [ 'ru', 'Russian' ]
);

# languages that are always in the TYP files (FR falls out if another language has to go in)
my @typfilelangfixed = (
  "xx",    # Unspecified
  "de",    # Deutsch / German
  "en",    # English
  "nl"     # Dutch
);

# Relation from languages to codepages
my %langcodepage = (
   'xx' => '1252' ,
   'de' => '1252' ,
   'en' => '1252' ,
   'fr' => '1252' ,
   'it' => '1252' ,
   'nl' => '1252' ,
   'pt' => '1252' ,   
   'pl' => '1250' ,
   'ru' => '1251' ,
   );

# Relation from (windows) codepage to isocode
my %cpisocode = (
   '1250' => 'iso-8859-2' ,
   '1251' => 'iso-8859-5' , 
   '1252' => 'iso-8859-1' ,
   );
   
# Define the download base URLs for the Elevation Data
my %elevationbaseurl = (
  'ele10' => "http://develop.freizeitkarte-osm.de/ele_10_100_200",
  'ele20' => "http://develop.freizeitkarte-osm.de/ele_20_100_500",
#  'ele25' => "http://develop.freizeitkarte-osm.de/ele_25_250_500",
  );
my %hqelevationbaseurl = (
  'ele10' => "http://develop.freizeitkarte-osm.de/ele_special/ele_10_100_200",
  'ele20' => "http://develop.freizeitkarte-osm.de/ele_special/ele_20_100_500",
  );
  
# Define the download URLS for the Boundaries (based on www.navmaps.eu/boundaries)
my @boundariesurl = (
  'http://develop.freizeitkarte-osm.de/boundaries/bounds.zip',
  'http://osm.thkukuk.de/data/bounds-latest.zip',
  );
my @seaboundariesurl = (
  'http://develop.freizeitkarte-osm.de/boundaries/sea.zip',
  'http://osm.thkukuk.de/data/sea-latest.zip',
  );

# Licenses - Default values
# --------------------------
# (encode decode sequence needed as mt.pl is in cp1252)
# Freizeitkarte: static but license type can be overwritten by more relevant value from elevation data

#my %lic_fzk = (
#   'license_type'           => encode('utf8', decode('iso-8859-1','CC BY 3.0')) ,
##   'license_string_short'   => encode('utf8', decode('iso-8859-1','FZK project 123456')) ,
#   'license_string_short'   => encode('utf8', decode('iso-8859-1','FZK project äöüéèê')) ,
#   'license_string_medium'  => encode('utf8', decode('iso-8859-1','FZK project (Freizeitkarte), freizeitkarte-osm.de')) ,
#   'license_string_long'    => encode('utf8', decode('iso-8859-1','FZK project (Freizeitkarte), freizeitkarte-osm.de, free for research and private use' )),
#   'data_provider_name'     => encode('utf8', decode('iso-8859-1','Freizeitkarte' )),
#   'data_provider_homepage' => encode('utf8', decode('iso-8859-1','freizeitkarte-osm.de' )),
#   'additional_info_de'     => encode('utf8', decode('iso-8859-1',"Die hier verfügbaren Karten stellen ein aus den Karten- und Höhendaten abgeleitetes Werk (produced work) dar. Die Karten können für private oder wissenschaftliche Zwecke frei (uneingeschränkt) genutzt werden.\n")) ,
#   'additional_info_en'     => encode('utf8', decode('iso-8859-1',"The available maps are a derived work from map and elevation data. The maps can be used free for personal or academic purposes.\n")) ,
#   'use_de'                 => encode('utf8', decode('iso-8859-1',"Nutzung des Kartenmaterial:\nDie Nutzung des Kartenmaterials erfolgt auf eigene Gefahr. Das Kartenmaterial und oder das Routing kann Fehler enthalten oder unzureichend sein. Die Ersteller dieser Karten übernehmen keinerlei Gewährleistung oder Haftung für Schäden die direkt oder indirekt durch die Nutzung des Kartenmaterial entstehen.\n")),
#   'use_en'                 => encode('utf8', decode('iso-8859-1',"Use of the maps:\nThe use of maps is at your own risk. The map data and / or the routing may contain errors or may be insufficient.\nThe creators of these maps are not liable for any damage resulting directly or indirectly from the use of the maps.\n")) ,
#   'help_de'                => encode('utf8', decode('iso-8859-1',"Deine Mithilfe ist erwünscht:\nHilf mit die OpenStreetMap-Quelldaten dieser Karte, und damit auch diese Themenkarte, zu verbessern. Fehlende oder inkorrekte Kartendaten kannst auch du auf OpenStreetMap eintragen oder korrigieren. Dies geht viel leichter als du vielleicht glaubst. Melde dich hierzu auf OpenStreetMap an und versuche es einfach mal. Alle anderen Kartennutzer können so von deinem Wissen profitieren.\nAuch Information über Defekte, die dir bei der Nutzung dieser Karte auffallen, sind hilfreich - ebenso Änderungs- oder Verbesserungsvorschläge.\nDanke für deine Unterstützung.\n ")),
#   'help_en'                => encode('utf8', decode('iso-8859-1',"Your help is welcome:\nYou can help to improve the OpenStreetMap source data, and therefore also this map. If something is missing or wrong in the source data you can add or correct that on OpenStreetMap. That's easier as you might think. Get registered on OpenStreetMap and just try it out. This way everyone can profit from your knowledge.\nInformation about defects found while using this map are also helpful. Also ideas about changes and improvments are very welcome.\nMany thanks for your support.\n")),
#   );
my %lic_fzk = ();

# OSM data: static
#my %lic_osm = (
#   'license_type'           => encode('utf8', decode('iso-8859-1','ODbl')) ,
##   'license_string_short'   => encode('utf8', decode('iso-8859-1','OSM contributors 123456')) ,
#   'license_string_short'   => encode('utf8', decode('iso-8859-1','OSM contributors äöüéèê')) ,
#   'license_string_medium'  => encode('utf8', decode('iso-8859-1','OSM contributors, www.openstreetmap.org')) ,
#   'license_string_long'    => encode('utf8', decode('iso-8859-1','OSM contributors, www.openstreetmap.org, ODbl')) ,
#   'data_provider_name'     => encode('utf8', decode('iso-8859-1','OpenStreetMap')) ,
#   'data_provider_homepage' => encode('utf8', decode('iso-8859-1','www.openstreetmap.org')) ,
#   'additional_info_de'     => encode('utf8', decode('iso-8859-1',"Die dargestellten Kartenobjekte basieren auf den Daten des OpenStreetMap-Projektes. OpenStreetMap ist eine freie, editierbare Karte der gesamten Welt, die von Menschen wie dir erstellt wird. OpenStreetMap ermöglicht es geographische Daten gemeinschaftlich von überall auf der Welt anzuschauen und zu bearbeiten.\n")) ,
#   'additional_info_en'     => encode('utf8', decode('iso-8859-1',"All maps are based on data from the OpenStreetMap project. OpenStreetMap is a free editable map of the whole world that is created by people like you. OpenStreetMap allows geographic data to look at collaborative way from anywhere in the world and edit it.\n")) ,
#   );
my %lic_osm = ();

# Elevation Data: default for viewfinderpanorama, can be overridden by sidefile to Elevation PBF: Hoehendaten_Freizeitkarte_SOMETHING.osm.pbf.license
#my %lic_ele = (
#   'license_type_strongest' => "1",
#   'license_type'           => encode('utf8', decode('iso-8859-1','free for research and private use')) ,
#   'license_string_short'   => encode('utf8', decode('iso-8859-1','U.S. Geological Survey or J. de Ferranti' )),
#   'license_string_medium'  => encode('utf8', decode('iso-8859-1','U.S. Geological Survey, eros.usgs.gov or viewfinderpanoramas by J. de Ferranti, www.viewfinderpanoramas.org')) ,
#   'license_string_long'    => encode('utf8', decode('iso-8859-1','U.S. Geological Survey (public domain), eros.usgs.gov or viewfinderpanoramas by J. de Ferranti (free for research and private use), www.viewfinderpanoramas.org')) ,
#   'data_provider_name'     => encode('utf8', decode('iso-8859-1','U.S. Geological Survey or viewfinderpanoramas by J. de Ferranti')) ,
#   'data_provider_homepage' => encode('utf8', decode('iso-8859-1','eros.usgs.gov or www.viewfinderpanoramas.org')) ,
#   'additional_info_de'     => encode('utf8', decode('iso-8859-1',"")) ,
#   'additional_info_en'     => encode('utf8', decode('iso-8859-1',"")) ,
#   );
my %lic_ele = ();

# Read the license default values
#read_default_licenses ();

# FZK maps: static
my @maps = (
  # ID, 'Karte', 'URL der Quelle', 'Code', 'language', 'oldName', 'Type', 'Parent'

  # Bundesländer
  [ -1,   'Bundeslaender',                        'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 5810, 'Freizeitkarte_BADEN-WUERTTEMBERG',     'http://download.geofabrik.de/europe/germany/baden-wuerttemberg-latest.osm.pbf',                     'BADEN-WUERTTEMBERG',       'de', 'Freizeitkarte_Baden-Wuerttemberg',        3, 'NA'             ],
  [ 5811, 'Freizeitkarte_BAYERN',                 'http://download.geofabrik.de/europe/germany/bayern-latest.osm.pbf',                                 'BAYERN',                   'de', 'Freizeitkarte_Bayern',                    3, 'NA'             ],
  [ 5812, 'Freizeitkarte_BERLIN',                 'http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf',                                 'BERLIN',                   'de', 'Freizeitkarte_Berlin',                    3, 'NA'             ],
  [ 5813, 'Freizeitkarte_BRANDENBURG',            'http://download.geofabrik.de/europe/germany/brandenburg-latest.osm.pbf',                            'BRANDENBURG',              'de', 'Freizeitkarte_Brandenburg',               3, 'NA'             ],
  [ 5814, 'Freizeitkarte_BREMEN',                 'http://download.geofabrik.de/europe/germany/bremen-latest.osm.pbf',                                 'BREMEN',                   'de', 'Freizeitkarte_Bremen',                    3, 'NA'             ],
  [ 5815, 'Freizeitkarte_HAMBURG',                'http://download.geofabrik.de/europe/germany/hamburg-latest.osm.pbf',                                'HAMBURG',                  'de', 'Freizeitkarte_Hamburg',                   3, 'NA'             ],
  [ 5816, 'Freizeitkarte_HESSEN',                 'http://download.geofabrik.de/europe/germany/hessen-latest.osm.pbf',                                 'HESSEN',                   'de', 'Freizeitkarte_Hessen',                    3, 'NA'             ],
  [ 5817, 'Freizeitkarte_MECKLENBURG-VORPOMMERN', 'http://download.geofabrik.de/europe/germany/mecklenburg-vorpommern-latest.osm.pbf',                 'MECKLENBURG-VORPOMMERN',   'de', 'Freizeitkarte_Mecklenburg-Vorpommern',    3, 'NA'             ],
  [ 5818, 'Freizeitkarte_NIEDERSACHSEN',          'http://download.geofabrik.de/europe/germany/niedersachsen-latest.osm.pbf',                          'NIEDERSACHSEN',            'de', 'Freizeitkarte_Niedersachsen',             3, 'NA'             ],
  [ 5819, 'Freizeitkarte_NORDRHEIN-WESTFALEN',    'http://download.geofabrik.de/europe/germany/nordrhein-westfalen-latest.osm.pbf',                    'NORDRHEIN-WESTFALEN',      'de', 'Freizeitkarte_Nordrhein-Westfalen',       3, 'NA'             ],
  [ 5820, 'Freizeitkarte_RHEINLAND-PFALZ',        'http://download.geofabrik.de/europe/germany/rheinland-pfalz-latest.osm.pbf',                        'RHEINLAND-PFALZ',          'de', 'Freizeitkarte_Rheinland-Pfalz',           3, 'NA'             ],
  [ 5821, 'Freizeitkarte_SAARLAND',               'http://download.geofabrik.de/europe/germany/saarland-latest.osm.pbf',                               'SAARLAND',                 'de', 'Freizeitkarte_Saarland',                  3, 'NA'             ],
  [ 5822, 'Freizeitkarte_SACHSEN',                'http://download.geofabrik.de/europe/germany/sachsen-latest.osm.pbf',                                'SACHSEN',                  'de', 'Freizeitkarte_Sachsen',                   3, 'NA'             ],
  [ 5823, 'Freizeitkarte_SACHSEN-ANHALT',         'http://download.geofabrik.de/europe/germany/sachsen-anhalt-latest.osm.pbf',                         'SACHSEN-ANHALT',           'de', 'Freizeitkarte_Sachsen-Anhalt',            3, 'NA'             ],
  [ 5824, 'Freizeitkarte_SCHLESWIG-HOLSTEIN',     'http://download.geofabrik.de/europe/germany/schleswig-holstein-latest.osm.pbf',                     'SCHLESWIG-HOLSTEIN',       'de', 'Freizeitkarte_Schleswig-Holstein',        3, 'NA'             ],
  [ 5825, 'Freizeitkarte_THUERINGEN',             'http://download.geofabrik.de/europe/germany/thueringen-latest.osm.pbf',                             'THUERINGEN',               'de', 'Freizeitkarte_Thueringen',                3, 'NA'             ],

  # Regierungsbezirke Baden-Wuerttemberg
  [ -1,   'Regierungsbezirke Baden-Wuerttemberg', 'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 5830, 'Freizeitkarte_FREIBURG',               'http://download.geofabrik.de/europe/germany/baden-wuerttemberg/freiburg-regbez-latest.osm.pbf',     'FREIBURG',                 'de', 'Freizeitkarte_Freiburg',                  3, 'NA'             ],
  [ 5831, 'Freizeitkarte_KARLSRUHE',              'http://download.geofabrik.de/europe/germany/baden-wuerttemberg/karlsruhe-regbez-latest.osm.pbf',    'KARLSRUHE',                'de', 'Freizeitkarte_Karlsruhe',                 3, 'NA'             ],
  [ 5832, 'Freizeitkarte_STUTTGART',              'http://download.geofabrik.de/europe/germany/baden-wuerttemberg/stuttgart-regbez-latest.osm.pbf',    'STUTTGART',                'de', 'Freizeitkarte_Stuttgart',                 3, 'NA'             ],
  [ 5833, 'Freizeitkarte_TUEBINGEN',              'http://download.geofabrik.de/europe/germany/baden-wuerttemberg/tuebingen-regbez-latest.osm.pbf',    'TUEBINGEN',                'de', 'Freizeitkarte_Tuebingen',                 3, 'NA'             ],

  # Regierungsbezirke Nordrhein-Westfalen
  [ -1,   'Regierungsbezirke Nordrhein-Westfalen','URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 5840, 'Freizeitkarte_ARNSBERG',               'http://download.geofabrik.de/europe/germany/nordrhein-westfalen/arnsberg-regbez-latest.osm.pbf',    'ARNSBERG',                 'de' , 'Freizeitkarte_Arnsberg',                 3, 'NA'             ],
  [ 5841, 'Freizeitkarte_DETMOLD',                'http://download.geofabrik.de/europe/germany/nordrhein-westfalen/detmold-regbez-latest.osm.pbf',     'DETMOLD',                  'de' , 'Freizeitkarte_Detmold',                  3, 'NA'             ],
  [ 5842, 'Freizeitkarte_DUESSELDORF',            'http://download.geofabrik.de/europe/germany/nordrhein-westfalen/duesseldorf-regbez-latest.osm.pbf', 'DUESSELDORF',              'de' , 'Freizeitkarte_Duesseldorf',              3, 'NA'             ],
  [ 5843, 'Freizeitkarte_KOELN',                  'http://download.geofabrik.de/europe/germany/nordrhein-westfalen/koeln-regbez-latest.osm.pbf',       'KOELN',                    'de' , 'Freizeitkarte_Koeln',                    3, 'NA'             ],
  [ 5844, 'Freizeitkarte_MUENSTER',               'http://download.geofabrik.de/europe/germany/nordrhein-westfalen/muenster-regbez-latest.osm.pbf',    'MUENSTER',                 'de' , 'Freizeitkarte_Muenster',                 3, 'NA'             ],

  # Regierungsbezirke Bayern
  [ -1,   'Regierungsbezirke Bayern',             'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 5850, 'Freizeitkarte_MITTELFRANKEN',          'http://download.geofabrik.de/europe/germany/bayern/mittelfranken-latest.osm.pbf',                   'MITTELFRANKEN',            'de', 'Freizeitkarte_Mittelfranken',             3, 'NA'             ],
  [ 5851, 'Freizeitkarte_NIEDERBAYERN',           'http://download.geofabrik.de/europe/germany/bayern/niederbayern-latest.osm.pbf',                    'NIEDERBAYERN',             'de', 'Freizeitkarte_Niederbayern',              3, 'NA'             ],
  [ 5852, 'Freizeitkarte_OBERBAYERN',             'http://download.geofabrik.de/europe/germany/bayern/oberbayern-latest.osm.pbf',                      'OBERBAYERN',               'de', 'Freizeitkarte_Oberbayern',                3, 'NA'             ],
  [ 5853, 'Freizeitkarte_OBERFRANKEN',            'http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf',                     'OBERFRANKEN',              'de', 'Freizeitkarte_Oberfranken',               3, 'NA'             ],
  [ 5854, 'Freizeitkarte_OBERPFALZ',              'http://download.geofabrik.de/europe/germany/bayern/oberpfalz-latest.osm.pbf',                       'OBERPFALZ',                'de', 'Freizeitkarte_Oberpfalz',                 3, 'NA'             ],
  [ 5855, 'Freizeitkarte_SCHWABEN',               'http://download.geofabrik.de/europe/germany/bayern/schwaben-latest.osm.pbf',                        'SCHWABEN',                 'de', 'Freizeitkarte_Schwaben',                  3, 'NA'             ],
  [ 5856, 'Freizeitkarte_UNTERFRANKEN',           'http://download.geofabrik.de/europe/germany/bayern/unterfranken-latest.osm.pbf',                    'UNTERFRANKEN',             'de', 'Freizeitkarte_Unterfranken',              3, 'NA'             ],

  # Regionen in Frankreich (unvollständig)
  [ -1,   'Regionen Frankreich',                  'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 5860, 'Freizeitkarte_LORRAINE',               'http://download.geofabrik.de/europe/france/lorraine-latest.osm.pbf',                                'LORRAINE',                 'de', 'Freizeitkarte_Lothringen',                3, 'NA'             ],
  [ 5861, 'Freizeitkarte_ALSACE',                 'http://download.geofabrik.de/europe/france/alsace-latest.osm.pbf',                                  'ALSACE',                   'de', 'Freizeitkarte_Elsass',                    3, 'NA'             ],
  [ 5862, 'Freizeitkarte_LAREUNION',              'http://download.geofabrik.de/europe/france/reunion-latest.osm.pbf',                                 'LAREUNION',                'de', 'no_old_name',                             3, 'NA'             ],

  # Countries
  # mapid:   6000 + ISO-3166 (numeric): http://en.wikipedia.org/wiki/ISO_3166-1_numeric
  # mapcode: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
  # country: https://en.wikipedia.org/wiki/ISO_3166-1
  [ -1,   'Europaeische Laender',                 'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 6008, 'Freizeitkarte_ALB',                    'http://download.geofabrik.de/europe/albania-latest.osm.pbf',                                        'ALB',                      'en', 'Freizeitkarte_Albanien',                  3, 'NA'             ],
  [ 6020, 'Freizeitkarte_AND',                    'http://download.geofabrik.de/europe/andorra-latest.osm.pbf',                                        'AND',                      'en', 'Freizeitkarte_Andorra',                   3, 'NA'             ],
  [ 6051, 'Freizeitkarte_ARM',                    'http://be.gis-lab.info/data/osm_dump/dump/latest/AM.osm.pbf',                                       'ARM',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6040, 'Freizeitkarte_AUT',                    'http://download.geofabrik.de/europe/austria-latest.osm.pbf',                                        'AUT',                      'de', 'Freizeitkarte_Oesterreich',               3, 'NA'             ],
  [ 6031, 'Freizeitkarte_AZE',                    'http://download.geofabrik.de/asia/azerbaijan-latest.osm.pbf',                                       'AZE',                      'en', 'no_old_name',                             3, 'NA'             ],
#  [ 6031, 'Freizeitkarte_AZE',                    'http://be.gis-lab.info/data/osm_dump/dump/latest/AZ.osm.pbf',                                       'AZE',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6112, 'Freizeitkarte_BLR',                    'http://download.geofabrik.de/europe/belarus-latest.osm.pbf',                                        'BLR',                      'ru', 'Freizeitkarte_Belarus',                   3, 'NA'             ],
  [ 6056, 'Freizeitkarte_BEL',                    'http://download.geofabrik.de/europe/belgium-latest.osm.pbf',                                        'BEL',                      'fr', 'Freizeitkarte_Belgien',                   3, 'NA'             ],
  [ 6070, 'Freizeitkarte_BIH',                    'http://download.geofabrik.de/europe/bosnia-herzegovina-latest.osm.pbf',                             'BIH',                      'en', 'Freizeitkarte_Bosnien-Herzegowina',       3, 'NA'             ],
  [ 6100, 'Freizeitkarte_BGR',                    'http://download.geofabrik.de/europe/bulgaria-latest.osm.pbf',                                       'BGR',                      'en', 'Freizeitkarte_Bulgarien',                 3, 'NA'             ],
  [ 6756, 'Freizeitkarte_CHE',                    'http://download.geofabrik.de/europe/switzerland-latest.osm.pbf',                                    'CHE',                      'de', 'Freizeitkarte_Schweiz',                   3, 'NA'             ],
  [ 6196, 'Freizeitkarte_CYP',                    'http://download.geofabrik.de/europe/cyprus-latest.osm.pbf',                                         'CYP',                      'en', 'Freizeitkarte_Zypern',                    3, 'NA'             ],
  [ 6203, 'Freizeitkarte_CZE',                    'http://download.geofabrik.de/europe/czech-republic-latest.osm.pbf',                                 'CZE',                      'en', 'Freizeitkarte_Tschechien',                3, 'NA'             ],
  [ 6208, 'Freizeitkarte_DNK',                    'http://download.geofabrik.de/europe/denmark-latest.osm.pbf',                                        'DNK',                      'en', 'Freizeitkarte_Daenemark',                 3, 'NA'             ],
  [ 6276, 'Freizeitkarte_DEU',                    'http://download.geofabrik.de/europe/germany-latest.osm.pbf',                                        'DEU',                      'de', 'Freizeitkarte_Deutschland',               3, 'NA'             ],
  [ 6724, 'Freizeitkarte_ESP',                    'http://download.geofabrik.de/europe/spain-latest.osm.pbf',                                          'ESP',                      'en', 'Freizeitkarte_Spanien',                   3, 'NA'             ],
  [ 6233, 'Freizeitkarte_EST',                    'http://download.geofabrik.de/europe/estonia-latest.osm.pbf',                                        'EST',                      'en', 'Freizeitkarte_Estland',                   3, 'NA'             ],
  [ 6234, 'Freizeitkarte_FRO',                    'http://download.geofabrik.de/europe/faroe-islands-latest.osm.pbf',                                  'FRO',                      'en', 'Freizeitkarte_Faeroeer',                  3, 'NA'             ],
  [ 6246, 'Freizeitkarte_FIN',                    'http://download.geofabrik.de/europe/finland-latest.osm.pbf',                                        'FIN',                      'en', 'Freizeitkarte_Finnland',                  3, 'NA'             ],
  [ 6250, 'Freizeitkarte_FRA',                    'http://download.geofabrik.de/europe/france-latest.osm.pbf',                                         'FRA',                      'fr', 'Freizeitkarte_Frankreich',                3, 'NA'             ],
  [ 6826, 'Freizeitkarte_GBR',                    'http://download.geofabrik.de/europe/great-britain-latest.osm.pbf',                                  'GBR',                      'en', 'Freizeitkarte_Grossbritannien',           3, 'NA'             ],
  [ 6268, 'Freizeitkarte_GEO',                    'http://be.gis-lab.info/data/osm_dump/dump/latest/GE.osm.pbf',                                       'GEO',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6300, 'Freizeitkarte_GRC',                    'http://download.geofabrik.de/europe/greece-latest.osm.pbf',                                         'GRC',                      'en', 'Freizeitkarte_Griechenland',              3, 'NA'             ],
  [ 6191, 'Freizeitkarte_HRV',                    'http://download.geofabrik.de/europe/croatia-latest.osm.pbf',                                        'HRV',                      'en', 'Freizeitkarte_Kroatien',                  3, 'NA'             ],
  [ 6348, 'Freizeitkarte_HUN',                    'http://download.geofabrik.de/europe/hungary-latest.osm.pbf',                                        'HUN',                      'en', 'Freizeitkarte_Ungarn',                    3, 'NA'             ],
  [ 6833, 'Freizeitkarte_IMN',                    'http://download.geofabrik.de/europe/isle-of-man-latest.osm.pbf',                                    'IMN',                      'en', 'Freizeitkarte_Insel-Man',                 3, 'NA'             ],
  [ 6372, 'Freizeitkarte_IRL',                    'http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf',                   'IRL',                      'en', 'Freizeitkarte_Irland',                    3, 'NA'             ],
  [ 6352, 'Freizeitkarte_ISL',                    'http://download.geofabrik.de/europe/iceland-latest.osm.pbf',                                        'ISL',                      'en', 'Freizeitkarte_Island',                    3, 'NA'             ],
  [ 6380, 'Freizeitkarte_ITA',                    'http://download.geofabrik.de/europe/italy-latest.osm.pbf',                                          'ITA',                      'it', 'Freizeitkarte_Italien',                   3, 'NA'             ],
  [ 6680, 'Freizeitkarte_KOSOVO',                 'http://download.geofabrik.de/europe/kosovo-latest.osm.pbf',                                         'KOSOSVO',                  'en', 'Freizeitkarte_Kosovo',                    3, 'NA'             ],
  [ 6428, 'Freizeitkarte_LVA',                    'http://download.geofabrik.de/europe/latvia-latest.osm.pbf',                                         'LVA',                      'en', 'Freizeitkarte_Lettland',                  3, 'NA'             ],
  [ 6438, 'Freizeitkarte_LIE',                    'http://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf',                                  'LIE',                      'en', 'Freizeitkarte_Liechtenstein',             3, 'NA'             ],
  [ 6440, 'Freizeitkarte_LTU',                    'http://download.geofabrik.de/europe/lithuania-latest.osm.pbf',                                      'LTU',                      'en', 'Freizeitkarte_Litauen',                   3, 'NA'             ],
  [ 6442, 'Freizeitkarte_LUX',                    'http://download.geofabrik.de/europe/luxembourg-latest.osm.pbf',                                     'LUX',                      'fr', 'Freizeitkarte_Luxemburg',                 3, 'NA'             ],
  [ 6504, 'Freizeitkarte_MAR',                    'http://download.geofabrik.de/africa/morocco-latest.osm.pbf',                                        'MAR',                      'en', 'Freizeitkarte_Marokko',                   3, 'NA'             ],
  [ 6492, 'Freizeitkarte_MCO',                    'http://download.geofabrik.de/europe/monaco-latest.osm.pbf',                                         'MCO',                      'en', 'Freizeitkarte_Monaco',                    3, 'NA'             ],
  [ 6498, 'Freizeitkarte_MDA',                    'http://download.geofabrik.de/europe/moldova-latest.osm.pbf',                                        'MDA',                      'en', 'Freizeitkarte_Moldawien',                 3, 'NA'             ],
  [ 6807, 'Freizeitkarte_MKD',                    'http://download.geofabrik.de/europe/macedonia-latest.osm.pbf',                                      'MKD',                      'en', 'Freizeitkarte_Mazedonien',                3, 'NA'             ],
  [ 6470, 'Freizeitkarte_MLT',                    'http://download.geofabrik.de/europe/malta-latest.osm.pbf',                                          'MLT',                      'en', 'Freizeitkarte_Malta',                     3, 'NA'             ],
  [ 6499, 'Freizeitkarte_MNE',                    'http://download.geofabrik.de/europe/montenegro-latest.osm.pbf',                                     'MNE',                      'en', 'Freizeitkarte_Montenegro',                3, 'NA'             ],
  [ 6528, 'Freizeitkarte_NLD',                    'http://download.geofabrik.de/europe/netherlands-latest.osm.pbf',                                    'NLD',                      'nl', 'Freizeitkarte_Niederlande',               3, 'NA'             ],
  [ 6578, 'Freizeitkarte_NOR',                    'http://download.geofabrik.de/europe/norway-latest.osm.pbf',                                         'NOR',                      'en', 'Freizeitkarte_Norwegen',                  3, 'NA'             ],
  [ 6616, 'Freizeitkarte_POL',                    'http://download.geofabrik.de/europe/poland-latest.osm.pbf',                                         'POL',                      'pl', 'Freizeitkarte_Polen',                     3, 'NA'             ],
  [ 6620, 'Freizeitkarte_PRT',                    'http://download.geofabrik.de/europe/portugal-latest.osm.pbf',                                       'PRT',                      'pt', 'Freizeitkarte_Portugal',                  3, 'NA'             ],
  [ 6642, 'Freizeitkarte_ROU',                    'http://download.geofabrik.de/europe/romania-latest.osm.pbf',                                        'ROU',                      'en', 'Freizeitkarte_Rumaenien',                 3, 'NA'             ],
  [ 6688, 'Freizeitkarte_SRB',                    'http://download.geofabrik.de/europe/serbia-latest.osm.pbf',                                         'SRB',                      'en', 'Freizeitkarte_Serbien',                   3, 'NA'             ],
  [ 6703, 'Freizeitkarte_SVK',                    'http://download.geofabrik.de/europe/slovakia-latest.osm.pbf',                                       'SVK',                      'en', 'Freizeitkarte_Slowakei',                  3, 'NA'             ],
  [ 6705, 'Freizeitkarte_SVN',                    'http://download.geofabrik.de/europe/slovenia-latest.osm.pbf',                                       'SVN',                      'en', 'Freizeitkarte_Slowenien',                 3, 'NA'             ],
  [ 6752, 'Freizeitkarte_SWE',                    'http://download.geofabrik.de/europe/sweden-latest.osm.pbf',                                         'SWE',                      'en', 'Freizeitkarte_Schweden',                  3, 'NA'             ],
  [ 6792, 'Freizeitkarte_TUR',                    'http://download.geofabrik.de/europe/turkey-latest.osm.pbf',                                         'TUR',                      'en', 'Freizeitkarte_Tuerkei',                   3, 'NA'             ],
  [ 6804, 'Freizeitkarte_UKR',                    'http://download.geofabrik.de/europe/ukraine-latest.osm.pbf',                                        'UKR',                      'en', 'Freizeitkarte_Ukraine',                   3, 'NA'             ],
  
  [ -1,   'Andere Laender',                       'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 6032, 'Freizeitkarte_ARG',                    'http://download.geofabrik.de/south-america/argentina-latest.osm.pbf',                               'ARG',                      'de', 'no_old_name',                             3, 'NA'             ],
  [ 6036, 'Freizeitkarte_AUS',                    'http://download.geofabrik.de/australia-oceania/australia-latest.osm.pbf',                           'AUS',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6068, 'Freizeitkarte_BOL',                    'http://download.geofabrik.de/south-america/bolivia-latest.osm.pbf',                                 'BOL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6076, 'Freizeitkarte_BRA',                    'http://download.geofabrik.de/south-america/brazil-latest.osm.pbf',                                  'BRA',                      'en', 'no_old_name',                             3, 'NA'             ],
#  [ 6124, 'Freizeitkarte_CAN',                    'http://download.geofabrik.de/north-america/canada-latest.osm.pbf',                                  'CAN',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6132, 'Freizeitkarte_CPV',                    'http://download.geofabrik.de/africa/cape-verde-latest.osm.pbf',                                     'CPV',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6144, 'Freizeitkarte_LKA',                    'http://download.geofabrik.de/asia/sri-lanka-latest.osm.pbf',                                        'LKA',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6152, 'Freizeitkarte_CHL',                    'http://download.geofabrik.de/south-america/chile-latest.osm.pbf',                                   'CHL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6170, 'Freizeitkarte_COL',                    'http://download.geofabrik.de/south-america/colombia-latest.osm.pbf',                                'COL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6218, 'Freizeitkarte_ECU',                    'http://download.geofabrik.de/south-america/ecuador-latest.osm.pbf',                                 'ECU',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6242, 'Freizeitkarte_FJI',                    'http://download.geofabrik.de/australia-oceania/fiji-latest.osm.pbf',                                'FJI',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6392, 'Freizeitkarte_JPN',                    'http://download.geofabrik.de/asia/japan-latest.osm.pbf',                                            'JPN',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6408, 'Freizeitkarte_KOR',                    'http://download.geofabrik.de/asia/south-korea-latest.osm.pbf',                                      'KOR',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6524, 'Freizeitkarte_NPL',                    'http://download.geofabrik.de/asia/nepal-latest.osm.pbf',                                            'NPL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6540, 'Freizeitkarte_NCL',                    'http://download.geofabrik.de/australia-oceania/new-caledonia-latest.osm.pbf',                       'NCL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6554, 'Freizeitkarte_NZL',                    'http://download.geofabrik.de/australia-oceania/new-zealand-latest.osm.pbf',                         'NZL',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6600, 'Freizeitkarte_PRY',                    'http://download.geofabrik.de/south-america/paraguay-latest.osm.pbf',                                'PRY',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6604, 'Freizeitkarte_PER',                    'http://download.geofabrik.de/south-america/peru-latest.osm.pbf',                                    'PER',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6704, 'Freizeitkarte_VNM',                    'http://download.geofabrik.de/asia/vietnam-latest.osm.pbf',                                          'VNM',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6740, 'Freizeitkarte_SUR',                    'http://download.geofabrik.de/south-america/suriname-latest.osm.pbf',                                'SUR',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6858, 'Freizeitkarte_URY',                    'http://download.geofabrik.de/south-america/uruguay-latest.osm.pbf',                                 'URY',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6710, 'Freizeitkarte_ZAF',                    'http://download.geofabrik.de/africa/south-africa-and-lesotho-latest.osm.pbf',                       'ZAF',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6360, 'Freizeitkarte_IDN',                    'http://download.geofabrik.de/asia/indonesia-latest.osm.pbf',                                        'IDN',                      'en', 'no_old_name',                             3, 'NA'             ],
  [ 6356, 'Freizeitkarte_IND',                    'http://download.geofabrik.de/asia/india-latest.osm.pbf',                                            'IND',                      'en', 'no_old_name',                             3, 'NA'             ],

  # Andere Regionen
#  [ -1,   'Andere Regionen',                      'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
#  [ 7010, 'Freizeitkarte_ALPS-SMALL',             'http://download.geofabrik.de/europe/alps-latest.osm.pbf',                                           'ALPS-SMALL',               'en', 'Freizeitkarte_Alpen',                     3, 'NA'             ],
#  [ 7020, 'Freizeitkarte_AZORES',                 'http://download.geofabrik.de/europe/azores-latest.osm.pbf',                                         'AZORES',                   'en', 'Freizeitkarte_Azoren',                    3, 'NA'             ],
#  [ 7030, 'Freizeitkarte_BRITISH-ISLES',          'http://download.geofabrik.de/europe/british-isles-latest.osm.pbf',                                  'BRITISH-ISLES',            'en', 'Freizeitkarte_Britische-Inseln',          3, 'NA'             ],
#  [ 7040, 'Freizeitkarte_IRELAND-ISLAND',         'http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf',                   'IRELAND-ISLAND',           'en', 'Freizeitkarte_Irland-Insel',              3, 'NA'             ],
#  [ 7050, 'Freizeitkarte_EUROP-RUSSIA',           'http://download.geofabrik.de/europe/russia-european-part-latest.osm.pbf',                           'EUROP-RUSSIA',             'en', 'Freizeitkarte_Euro-Russland',             3, 'NA'             ],
#  [ 7060, 'Freizeitkarte_CANARY-ISLANDS',         'http://download.geofabrik.de/africa/canary-islands-latest.osm.pbf',                                 'CANARY-ISLANDS',           'en', 'Freizeitkarte_Kanarische-Inseln',         3, 'NA'             ],

  # PLUS Länder, Ländercodes: 7000 + ISO-3166 (numerisch)
  [ -1,   'Freizeitkarte PLUS Laender',           'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 7040, 'Freizeitkarte_AUT+',                   'NA',                                                                                                'AUT+',                     'de', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7056, 'Freizeitkarte_BEL+',                   'NA',                                                                                                'BEL+',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7756, 'Freizeitkarte_CHE+',                   'NA',                                                                                                'CHE+',                     'de', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7276, 'Freizeitkarte_DEU+',                   'NA',                                                                                                'DEU+',                     'de', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7208, 'Freizeitkarte_DNK+',                   'NA',                                                                                                'DNK+',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7724, 'Freizeitkarte_ESP+',                   'NA',                                                                                                'ESP+',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7250, 'Freizeitkarte_FRA+',                   'NA',                                                                                                'FRA+',                     'fr', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7826, 'Freizeitkarte_GBR+',                   'NA',                                                                                                'GBR+',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7372, 'Freizeitkarte_IRL+',                   'NA',                                                                                                'IRL+',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7380, 'Freizeitkarte_ITA+',                   'NA',                                                                                                'ITA+',                     'it', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7528, 'Freizeitkarte_NLD+',                   'NA',                                                                                                'NLD+',                     'nl', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7620, 'Freizeitkarte_PRT+',                   'NA',                                                                                                'PRT+',                     'pt', 'no_old_name',                             2, 'EUROPE'         ],

  [ -1,   'Andere Laender',                       'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 7032, 'Freizeitkarte_ARG+',                   'NA',                                                                                                'ARG+',                     'en', 'no_old_name',                             2, 'SOUTHAMERICA'   ],



  # Sonderkarten wie z.B. FZK-eigene Extrakte (alle ohne geofabrik-Download (NA = Not Applicable); Ausnahme Europa)
  [ -1,   'Freizeitkarte Regionen',               'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 8888, 'Freizeitkarte_EUROPE',                 'http://download.geofabrik.de/europe-latest.osm.pbf',                                                'EUROPE',                   'en', 'no_old_name',                             1, 'NA'             ],
  [ 8010, 'Freizeitkarte_GBR_IRL',                'NA',                                                                                                'GBR_IRL',                  'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8020, 'Freizeitkarte_ALPS',                   'NA',                                                                                                'ALPS',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8030, 'Freizeitkarte_DNK_NOR_SWE_FIN',        'NA',                                                                                                'DNK_NOR_SWE_FIN',          'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8040, 'Freizeitkarte_BEL_NLD_LUX',            'NA',                                                                                                'BEL_NLD_LUX',              'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8050, 'Freizeitkarte_ESP_PRT',                'NA',                                                                                                'ESP_PRT',                  'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8060, 'Freizeitkarte_PYRENEES',               'NA',                                                                                                'PYRENEES',                 'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8070, 'Freizeitkarte_CARPATHIAN',             'NA',                                                                                                'CARPATHIAN',               'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8080, 'Freizeitkarte_BALKAN',                 'NA',                                                                                                'BALKAN',                   'en', 'no_old_name',                             2, 'EUROPE'         ],

  [ 8889, 'Freizeitkarte_SOUTHAMERICA',           'http://download.geofabrik.de/south-america-latest.osm.pbf',                                         'SOUTHAMERICA',             'en', 'no_old_name',                             1, 'NA'             ],
  [ 8510, 'Freizeitkarte_MISIONES',               'NA',                                                                                                'MISIONES',                 'de', 'no_old_name',                             2, 'SOUTHAMERICA'   ],
  [ 8520, 'Freizeitkarte_SAOPAULO',               'NA',                                                                                                'SAOPAULO',                 'de', 'no_old_name',                             2, 'SOUTHAMERICA'   ],

  # Andere Regionen
  [ -1,   'Andere Regionen',                       'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
# [ 9010, 'Freizeitkarte_RUS_EUR',                 'http://download.geofabrik.de/europe/russia-european-part-latest.osm.pbf',                           'RUS_EUR',                 'ru', 'Freizeitkarte_Euro-Russland',             1, 'NA'             ],
# [ 9011, 'Freizeitkarte_RUS',                     'http://data.gis-lab.info/osm_dump/dump/latest/RU.osm.pbf',                                          'RUS',                     'ru', 'no_old_name',                             1, 'NA'             ],
  [ 9011, 'Freizeitkarte_RUS',                     'http://download.geofabrik.de/russia-latest.osm.pbf',                                                'RUS',                     'ru', 'no_old_name',                             1, 'NA'             ],
  [ 9020, 'Freizeitkarte_ESP_CANARIAS',            'http://download.geofabrik.de/africa/canary-islands-latest.osm.pbf',                                 'ESP_CANARIAS',            'en', 'Freizeitkarte_Kanarische-Inseln',         3, 'NA'             ],
  [ 9030, 'Freizeitkarte_RUS_CENTRAL_FD+',         'NA',                                                                                                'RUS_CENTRAL_FD+',         'ru', 'no_old_name',                             2, 'RUS'            ],
  [ 9040, 'Freizeitkarte_AZORES',                  'http://download.geofabrik.de/europe/azores-latest.osm.pbf',                                         'AZORES',                  'pt', 'Freizeitkarte_Azoren',                    3, 'NA'             ],
  [ 9050, 'Freizeitkarte_ISR_PSE',                 'http://download.geofabrik.de/asia/israel-and-palestine-latest.osm.pbf',                             'ISR_PSE',                 'en', 'Freizeitkarte_Israel_Palaestina',         3, 'NA'             ],
  [ 9060, 'Freizeitkarte_MYS_SGP_BRN',             'http://download.geofabrik.de/asia/malaysia-singapore-brunei-latest.osm.pbf',                        'MYS_SGP_BRN',             'en', 'no_old_name',                             3, 'NA'             ],

  # Andere Regionen
  [ 9701, 'Freizeitkarte_US_WASHINGTON',           'http://download.geofabrik.de/north-america/us/washington-latest.osm.pbf',                           'US_WASHINGTON',           'en', 'no_old_name',                             3, 'NA'             ],
  [ 9800, 'Freizeitkarte_CENTRAL_AMERICA',         'http://download.geofabrik.de/central-america-latest.osm.pbf',                                       'CENTRAL_AMERICA',         'en', 'no_old_name',                             3, 'NA'             ],
  [ 9810, 'Freizeitkarte_US_MIDWEST',              'http://download.geofabrik.de/north-america/us-midwest-latest.osm.pbf',                              'US_MIDWEST',              'en', 'no_old_name',                             3, 'NA'             ],
  [ 9811, 'Freizeitkarte_US_NORTHEAST',            'http://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf',                            'US_NORTHEAST',            'en', 'no_old_name',                             3, 'NA'             ],
  [ 9812, 'Freizeitkarte_US_PACIFIC',              'http://download.geofabrik.de/north-america/us-pacific-latest.osm.pbf',                              'US_PACIFIC',              'en', 'no_old_name',                             3, 'NA'             ],
  [ 9813, 'Freizeitkarte_US_SOUTH',                'http://download.geofabrik.de/north-america/us-south-latest.osm.pbf',                                'US_SOUTH',                'en', 'no_old_name',                             3, 'NA'             ],
  [ 9814, 'Freizeitkarte_US_WEST',                 'http://download.geofabrik.de/north-america/us-west-latest.osm.pbf',                                 'US_WEST',                 'en', 'no_old_name',                             3, 'NA'             ],
  [ 9820, 'Freizeitkarte_US_ALASKA',               'http://download.geofabrik.de/north-america/us/alaska-latest.osm.pbf',                               'US_ALASKA',               'en', 'no_old_name',                             3, 'NA'             ],
  [ 9830, 'Freizeitkarte_US_HAWAII',               'http://download.geofabrik.de/north-america/us/hawaii-latest.osm.pbf',                               'US_HAWAII',               'en', 'no_old_name',                             3, 'NA'             ],
  [ 9850, 'Freizeitkarte_CAN_AB',                  'http://download.geofabrik.de/north-america/canada/alberta-latest.osm.pbf',                          'CAN_AB',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9851, 'Freizeitkarte_CAN_BC',                  'http://download.geofabrik.de/north-america/canada/british-columbia-latest.osm.pbf',                 'CAN_BC',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9852, 'Freizeitkarte_CAN_MB',                  'http://download.geofabrik.de/north-america/canada/manitoba-latest.osm.pbf',                         'CAN_MB',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9853, 'Freizeitkarte_CAN_NB',                  'http://download.geofabrik.de/north-america/canada/new-brunswick-latest.osm.pbf',                    'CAN_NB',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9854, 'Freizeitkarte_CAN_NL',                  'http://download.geofabrik.de/north-america/canada/newfoundland-and-labrador-latest.osm.pbf',        'CAN_NL',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9855, 'Freizeitkarte_CAN_NS',                  'http://download.geofabrik.de/north-america/canada/nova-scotia-latest.osm.pbf',                      'CAN_NS',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9856, 'Freizeitkarte_CAN_NT',                  'http://download.geofabrik.de/north-america/canada/northwest-territories-latest.osm.pbf',            'CAN_NT',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9857, 'Freizeitkarte_CAN_NU',                  'http://download.geofabrik.de/north-america/canada/nunavut-latest.osm.pbf',                          'CAN_NU',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9858, 'Freizeitkarte_CAN_ON',                  'http://download.geofabrik.de/north-america/canada/ontario-latest.osm.pbf',                          'CAN_ON',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9859, 'Freizeitkarte_CAN_PE',                  'http://download.geofabrik.de/north-america/canada/prince-edward-island-latest.osm.pbf',             'CAN_PE',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9860, 'Freizeitkarte_CAN_QC',                  'http://download.geofabrik.de/north-america/canada/quebec-latest.osm.pbf',                           'CAN_QC',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9861, 'Freizeitkarte_CAN_SK',                  'http://download.geofabrik.de/north-america/canada/saskatchewan-latest.osm.pbf',                     'CAN_SK',                  'en', 'no_old_name',                             3, 'NA'             ],
  [ 9862, 'Freizeitkarte_CAN_YT',                  'http://download.geofabrik.de/north-america/canada/yukon-latest.osm.pbf',                            'CAN_YT',                  'en', 'no_old_name',                             3, 'NA'             ],


  # For faster test runs with regions
  [ -1,   'Regions - Maps for test purposes',     'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 9990, 'Freizeitkarte_CHE_R',                  'http://download.geofabrik.de/europe/switzerland-latest.osm.pbf',                                    'CHE_R',                    'de', 'no_old_name',                             1, 'NA'             ],
  [ 9991, 'Freizeitkarte_ZUG+',                   'NA',                                                                                                'ZUG+',                     'de', 'no_old_name',                             2, 'CHE_R'          ],
  [ 9992, 'Freizeitkarte_ZHSEE+',                 'NA',                                                                                                'ZHSEE+',                   'de', 'no_old_name',                             2, 'CHE_R'          ],
  
  
);

# pseudo constants
my $EMPTY = q{};

my $MAPID      = 0;
my $MAPNAME    = 1;
my $OSMURL     = 2;
my $MAPCODE    = 3;
my $MAPLANG    = 4;
my $MAPNAMEOLD = 5;
my $MAPTYPE    = 6;
my $MAPPARENT  = 7;

my $ACTIONNAME = 0;
my $ACTIONDESC = 1;
my $ACTIONOPT  = 2;
my $ACTIONLANGDIR = 3;
my $ACTIONTARGET = 4;

my $LANGCODE = 0;
my $LANGDESC = 1;

my $VERSION = '1.3.17 - 2019/04/14';

# Maximale Speichernutzung (Heapsize im MB) beim Splitten und Compilieren
my $javaheapsize = 1536;

# Maximale Anzahl an zu benutzenden CPU-Kernen beim Compilieren (mkgmap)
my $max_jobs = $EMPTY;

# Maximale Anzahl an zu benutzenden CPU-Kernen beim Splitten (splitter)
my $max_threads = $EMPTY;

# basepath
# fixed below statment, did only work if cwd was already $BASEPATH
#my $BASEPATH = getcwd ( $PROGRAM_NAME ) ;
my $BASEPATH = dirname ( abs_path( $PROGRAM_NAME ) );

# Read the license default values
read_default_licenses ();

## Global PC_ReturnCode - used mainly for process_command () - to be rechecked and solved differently eventually
#my $pc_returncode = 0;

# program startup
# ---------------
my $programName = basename ( $PROGRAM_NAME );
my $programInfo = "$programName - Map Tool for creating Garmin maps";
printf { *STDOUT } ( "\n%s, %s\n\n", $programInfo, $VERSION );

# Get some Details about OS
#---------------------------------------------
my $os_sysname  = "";
my $os_nodename = "";
my $os_release  = "";
my $os_version  = "";
my $os_machine  = "";
my $os_archbit  = "";
get_osdetails();



# OS X = 'darwin'; Windows = 'MSWin32'; Linux = 'linux'; FreeBSD = 'freebsd'; OpenBSD = 'openbsd';
# printf { *STDOUT } ( "OSNAME = %s\n", $OSNAME );
# printf { *STDOUT } ( "PERL_VERSION = %s\n", $PERL_VERSION );
# printf { *STDOUT } ( "BASEPATH = %s\n\n", $BASEPATH );

# command line parameters
my $help     = $EMPTY;
my $optional = $EMPTY;
my $ram      = $EMPTY;
my $cores    = 2;
my $ele      = 20;
my $hqele    = $EMPTY;
my $clm      = 1;   # eventually unused ?
my $typfile  = $EMPTY;
my $styledir = $EMPTY;
my $language = $EMPTY;
my $nametaglist = $EMPTY;
my $unicode     = $EMPTY;
my $downloadbar = $EMPTY;
my $continuedownload = $EMPTY;
my $downloadspeed = $EMPTY;

my $dempath = $EMPTY;
my $demdists = $EMPTY;
my $demtype = $EMPTY; 

my $actionname = $EMPTY;
my $actiondesc = $EMPTY;
my $actionlangdir = $EMPTY;
my $actiontarget = $EMPTY;

# The argument containing MapID, MapName or MapCode comes first into this Variable
my $mapinput   = $EMPTY;

my $mapid      = -1;
my $mapname    = $EMPTY;
my $mapnameold = $EMPTY;
my $osmurl     = $EMPTY;
my $mapcode    = $EMPTY;
my $maplang    = $EMPTY;
my $mapcodepage= $EMPTY;
my $mapisolang = $EMPTY;
my $maptype    = $EMPTY;
my $mapparent  = $EMPTY;
my $langdesc   = $EMPTY;
my $maptypfile = "freizeit.TYP";
my $mapstyle    = "fzk";
my $mapstyledir = 'style/fzk';

my $releasestring  = $EMPTY;
my $releasenumeric = $EMPTY;

my $error   = -1;
my $command = $EMPTY;

my $alltypfile = $EMPTY;
my $typfilelangcode = $EMPTY;

my $mkgmap_common_parameter = $EMPTY;


# get the command line parameters
if ( ! GetOptions ( 'h|?|help' => \$help, 'o|optional' => \$optional, 'u|unicode' => \$unicode, 'downloadbar' => \$downloadbar, 'continuedownload' => \$continuedownload, 'downloadspeed=s' => \$downloadspeed, 'ram=s' => \$ram, 'cores=s' => \$cores, 'ele=s' => \$ele, 'hqele' => \$hqele, 'typfile=s' => \$typfile, 'style=s' => \$styledir, 'language=s' => \$language, 'ntl=s' => \$nametaglist, 'dempath=s' => \$dempath, 'demdists=s' => \$demdists, 'demtype=s' => \$demtype ) ) {
  printf { *STDOUT } ( "ERROR:\n  Unknown option.\n\n\n" );
  show_usage ();
  exit(1);   
 }

# Show help if wished
if ( ( $help ) || ( $optional ) ) {
  show_help ();
  exit(0);
}

if ( $ram ne $EMPTY ) {
  $javaheapsize = $ram;
}

# Beispiel: --max-jobs=4
if ( lc ( $cores ) eq 'max' ) {
  $max_jobs    = ' --max-jobs';
  $max_threads = ' --max-threads=auto';
}
else {
  $max_jobs    = ' --max-jobs=' . $cores;
  $max_threads = ' --max-threads=' . $cores;
}

# Fetch first only the actionname from the Arguments, there are some actions not needing map
$actionname = $ARGV[ 0 ];

# Definitely not enough arguments
if ( ( $#ARGV + 1 ) < 1 ) {
  printf { *STDOUT } ( "ERROR:\n  Not enough Arguments.\n\n\n" );
  show_usage ();
  exit(1);
}

# Checking Arguments for valid actions
$error = 1;
for my $actiondata ( @actions ) {
  if ( @$actiondata[ $ACTIONNAME ] eq $actionname ) {
    $actionname = @$actiondata[ $ACTIONNAME ];
    $actiondesc = @$actiondata[ $ACTIONDESC ];
    $actionlangdir = @$actiondata[ $ACTIONLANGDIR ];
    $actiontarget = @$actiondata[ $ACTIONTARGET ];
    $error      = 0;
    last;
  }
}

# Error due to invalid action
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  Action '" . $actionname . "' not valid.\n\n\n" );
  show_usage ();
  exit(1);
}


# First we handle those actiona that either complete the environment or don't need a complete one
# - bootstrap, checkurl, fingerprint
# (help is handled already before)

# Are we doing bootstrapping for completing the environment ?
if ( $actionname eq 'bootstrap' ) {
  printf { *STDOUT } ( "Action = %s\n", $actiondesc );
  bootstrap_environment ();
  exit(0);
}
# Now let's handle other actions that do not need maps
elsif ( $actionname eq 'checkurl' ) {
  show_actionsummary ();
  check_downloadurls ();
  exit(0);
}
elsif ( $actionname eq 'fingerprint' ) {
#  printf { *STDOUT } ( "Action = %s\n", $actiondesc );
  show_actionsummary ();
  show_fingerprint ();
  exit(0);
}

# After that we only have actions that need a complete environment (bootstrapping done)
# Therefore we need to check the environment now
check_environment ();

# Not related to a map directly (no map argument needed)
if ( $actionname eq 'alltypfiles' ) {
  show_actionsummary ();
  $alltypfile = "yes";
  create_alltypfile_languages ();
  exit(0);
}
elsif ( $actionname eq 'replacetyp' ) {
  show_actionsummary ();
  $alltypfile = "yes";
  create_allreplacetyp_languages ();
  exit(0);
}

# Here we start with actions that need a map and therefore an additional argument

# Definitely not enough arguments
if ( ( $#ARGV + 1 ) < 2 ) {
  printf { *STDOUT } ( "ERROR:\n  Not enough Arguments for the action '" . $actionname . "'. MapID, MapName or MapCode needed too.\n\n\n" );
  show_usage ();
  exit(1);
}

# Now get the mapinput containing either mapid, mapcode or mapname
$mapinput    = $ARGV[ 1 ];
#$mapid      = $ARGV[ 1 ];
#$mapcode    = $ARGV[ 1 ];
#$mapname    = $ARGV[ 1 ];


# Definitely not enough arguments
if ( ( $#ARGV + 1 ) < 2 ) {
  printf { *STDOUT } ( "ERROR:\n  Not enough Arguments\n\n\n" );
  show_usage ();
  exit(1);
}

# Checking arguments for valid maps
$error = 1;
for my $mapdata ( @maps ) {
  if ( ( lc @$mapdata[ $MAPNAME ] eq lc $mapinput ) || ( lc @$mapdata[ $MAPID ] eq lc $mapinput ) || ( lc @$mapdata[ $MAPCODE ] eq lc $mapinput ) ) {
    $mapid      = @$mapdata[ $MAPID ];
    $mapname    = @$mapdata[ $MAPNAME ];
    $osmurl     = @$mapdata[ $OSMURL ];
    $mapcode    = @$mapdata[ $MAPCODE ];
    $maplang    = @$mapdata[ $MAPLANG ];
    $mapnameold = @$mapdata[ $MAPNAMEOLD ];
    $maptype    = @$mapdata[ $MAPTYPE ];
    $mapparent  = @$mapdata[ $MAPPARENT ];
    $error      = 0;
    last;
  }
}

# Error due to invalid map name/code
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  Map '" . $mapinput . "' not valid (invalid ID, code or name).\n\n\n" );
  show_usage ();
  exit(1);
}

# Default Map Language overwritten ?
if ( $language ne $EMPTY ) {
  $maplang = $language;
}

# Checking if this language is supported
$error = 1;
for my $languagedata ( @supportedlanguages ) {
  if ( @$languagedata[ $LANGCODE ] eq $maplang ) {
    $langdesc = @$languagedata[ $LANGDESC ];
    $error    = 0;
    last;
  }
}

# Check if the user did choose unicode, else set the codepage to the codepage of the choosen language
if ( $unicode ) {
  $mapcodepage = 65001;
  $mapisolang  = 'utf-8';
}
else {
  $mapcodepage = $langcodepage{$maplang};
  $mapisolang  = $cpisocode{$mapcodepage};
}


# Error due to invalid language code
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  Language '" . $maplang . "' not supported.\n\n\n" );
  show_usage ();
  exit(1);
}

# Did user choose a TYP file via argument -typfile=xx ?
if ( $typfile ne $EMPTY ) {
  $maptypfile = $typfile;
}

# Checking if this TYP file exists
$error = 1;
if ( -e "$BASEPATH/TYP/" . basename("$maptypfile", (".TYP", ".typ" ) ) . ".txt" ) {
      $error    = 0;
      $maptypfile = basename("$maptypfile", (".TYP", ".typ" ) ) ;
}
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  TYP file '" . $maptypfile . "' not found.\n\n\n" );
  show_usage ();
  exit(1);
}

# Did user choose a style dir via argument -style=xx ?
if ( $styledir ne $EMPTY ) {
  $mapstyle = $styledir;
}

# Check if the choosen style does exist and set the Style Directory accordingly by testing points-master in the choosen dir
$error = 1;
if ( ( -e "$BASEPATH/style/$mapstyle/points" ) || ( -e "$BASEPATH/style/$mapstyle/points-master" ) ) {
        $error   = 0;
        $mapstyledir = "style/$mapstyle";
}
elsif ( ( $mapstyle eq "fzk" ) && ( -e "$BASEPATH/style/points-master") ) {
        $error   = 0;
        $mapstyledir = "style";
}
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  Style '" . $mapstyle . "' not found.\n\n\n" );
  show_usage ();
  exit(1);
}
  

# Check nametaglist (if given) for potential problems
if ( $nametaglist ne $EMPTY ) {
 
   # Let's check if we have the general fallback 'name' somewhere in the specified nametaglist
   if ( $nametaglist !~ /(^|,)name(,|$)/ ) {
	 printf { *STDOUT } ( "WARNING:\n  The specified name-tag-list '" . $nametaglist . "' does not contain the tag 'name'.\n  Make sure this is really what you want\n\n\n" );
   }
}

# Check / Set DEM options
if ( $dempath ne $EMPTY ) {

   # Create absolute path for dempath: absolut, relativ to cwd or relative to $BASEPATH
   if ( -e "$BASEPATH/$dempath" ) {
     $dempath="$BASEPATH/$dempath";
   }
   elsif ( -e "$dempath" ) {
     $dempath = abs_path( $dempath );
     }
   else {
     die "error: dempath $dempath not existing\n";
   }
   
   if (( $demtype ne $EMPTY ) && ( $demdists ne $EMPTY) ) {
 	 printf { *STDOUT } ( "WARNING:\n  --demdists overwrites defaults choosen by --demtype.\n  Make sure this is really what you want\n\n\n" );  
   }
#   elsif (( $demtype eq $EMPTY ) && ( $demdists eq $EMPTY) ) {
# 	 # all fine, no warning needed, will create only one DEM Level
#	 #printf { *STDOUT } ( "WARNING:\n  --demdists overwrites defaults choosen by --demtype.\n  Make sure this is really what you want\n\n\n" );  
#   }
   elsif (( $demtype eq "1" ) && ( $demdists eq $EMPTY) ) {
      $demdists="3312,6624,9936,13248,16560,19872,23184,26496";
   }
   elsif (( $demtype eq "3" ) && ( $demdists eq $EMPTY) ) {
      $demdists="9942,19884,29826,39768,49710,59652,69594,79536";
   }
   elsif ( $demtype ne $EMPTY ) {
 	 printf { *STDOUT } ( "WARNING:\n  demtype value '" . $demtype . "' is not supported, no dem-dists value are set for mkgmap.\n  Make sure this is really what you want\n\n\n" );     
   }
}

# Create the WORKDIR, WORKDIRLANG and the INSTALLDIR variables, used at a lot of places
my $WORKDIR     = '';
my $WORKDIRLANG = '';
my $INSTALLDIR  = '';

# If this map is a downloaded extract from which we extract further regions
# (No distinction anymore needed between different maptypes)
#if ( $maptype == 1 ) {
#  # no language code added as this map itself isn't thought to be built up to the end
#  $WORKDIR    = "$BASEPATH/work/$mapname";
#  $INSTALLDIR = "$BASEPATH/install/$mapname";
#}
#else {
#  # Normal map, add language code to WORKDIR and INSTALLDIR
#  $WORKDIR    = "$BASEPATH/work/$mapname" . "_$maplang";
#  $INSTALLDIR = "$BASEPATH/install/$mapname" . "_$maplang";
#}
$WORKDIR     = "$BASEPATH/work/$mapname";
$WORKDIRLANG = "$BASEPATH/work/$mapname" . "_$maplang";
$INSTALLDIR  = "$BASEPATH/install/$mapname" . "_$maplang";

# Put the needed release numbers together
get_release ();

# Print out the Information about the choosen action and map
#printf { *STDOUT } ( "Action = %s\n", $actiondesc );
#printf { *STDOUT } ( "Map  = %s (%s)\n", $mapname, $mapid );
show_actionsummary ();


# In case we run command on wrong target, issue warning
unless ( $actiontarget =~ /$maptype/ ) {
  show_wrongtargetwarning ();
}


# Make sure that the directories set above are existing
create_dirs   ();


# Execute the choosen action
if ( $actionname eq 'create' ) {
  purge_dirs  ();
  create_dirs ();
}
elsif ( $actionname eq 'fetch_osm' ) {
  fetch_osmdata ();
}
elsif ( $actionname eq 'fetch_ele' ) {
  fetch_eledata ();
}
elsif ( $actionname eq 'check_osmid' ) {
  check_osmid ();
}
elsif ( $actionname eq 'join' ) {
  check_osmid  ();
  join_mapdata ();
}
elsif ( $actionname eq 'split' ) {
  split_mapdata ();
}
elsif ( $actionname eq 'build' ) {
  update_ele_license       ();
  create_cfgfile           ();
  create_typtranslations   ();
  compile_typfiles         ();
  create_typfile           ();
  create_styletranslations ();
  preprocess_styles        ();
  build_map                ();
}
elsif ( $actionname eq 'gmap' ) {
  create_typfile  ();
  create_gmapfile ();
}
elsif ( $actionname eq 'nsis' ) {
  update_ele_license       ();
  create_typfile      ();
  create_nsis_nsi_full ();
  create_nsis_exe_full ();
}
elsif ( $actionname eq 'nsisgmap' ) {
  update_ele_license       ();
  create_nsis_nsi_gmap ();
  create_nsis_exe_gmap ();
}

elsif ( $actionname eq 'gmapsupp' ) {
  update_ele_license       ();
  create_typfile      ();
  create_gmapsuppfile ();
}
elsif ( $actionname eq 'imagedir' ) {
  update_ele_license       ();
  create_typfile         ();
  create_image_directory ();
}
elsif ( $actionname eq 'cfg' ) {
  update_ele_license       ();
  create_cfgfile ();
}
elsif ( $actionname eq 'typ' ) {
  create_typtranslations ();
  compile_typfiles ();
  create_typfile ();
}
elsif ( $actionname eq 'compiletyp' ) {
  create_typtranslations ();
  compile_typfiles ();
}
elsif ( $actionname eq 'gmap2' ) {
  update_ele_license       ();
  create_typfile   ();
  create_gmap2file ();
}
elsif ( $actionname eq 'gmap3' ) {
  update_ele_license       ();
  create_typfile   ();
  create_gmapfile_jmc_cli ();
}
elsif ( $actionname eq 'bim' ) {
  purge_dirs               ();
  create_dirs              ();
  # If this map is a regions that needed to be extracted, try to fetch the extracted region
  if ( $maptype == 2 ) {
	  extract_osm          ();
  }
  else {
	  fetch_osmdata        ();
  }
  fetch_eledata            ();
  check_osmid              ();
  join_mapdata             ();
  split_mapdata            ();
  update_ele_license       ();
  create_cfgfile           ();
  create_typtranslations   ();
  compile_typfiles         ();
  create_typfile           ();
  create_styletranslations ();
  preprocess_styles        ();
  build_map                ();
}
elsif ( $actionname eq 'bam' ) {
  create_typfile         ();
  create_image_directory ();
  create_gmapfile        ();
  create_gmapsuppfile    ();
  update_ele_license       ();
  create_nsis_nsi_gmap   ();
  create_nsis_exe_gmap   ();
  create_nsis_nsi_full    ();
  create_nsis_exe_full    ();
}
elsif ( $actionname eq 'pmd' ) {
  purge_dirs               ();
  create_dirs              ();
  # If this map is a regions that needed to be extracted, try to fetch the extracted region
  if ( $maptype == 2 ) {
	  extract_osm          ();
  }
  else {
	  fetch_osmdata        ();
  }
  fetch_eledata            ();
  check_osmid              ();
  join_mapdata             ();
  split_mapdata            ();
}
elsif ( $actionname eq 'bml' ) {
  update_ele_license       ();
  create_cfgfile           ();
  create_typtranslations   ();
  compile_typfiles         ();
  create_typfile           ();
  create_styletranslations ();
  preprocess_styles        ();
  build_map                ();
  create_image_directory ();
  create_gmapfile        ();
  create_gmapsuppfile    ();
  create_nsis_nsi_gmap    ();
  create_nsis_exe_gmap   ();
  create_nsis_nsi_full    ();
  create_nsis_exe_full    ();
}
elsif ( $actionname eq 'zip' ) {
  zip_maps ();
}
elsif ( $actionname eq 'regions' ) {
  extract_regions ();
}
elsif ( $actionname eq 'fetch_map' ) {
  fetch_mapdata ();
}
elsif ( $actionname eq 'extract_osm' ) {
  extract_osm ();
}
exit ( 0 );

# ==================================================================
#
# Start of Subroutines 
# --------------------
#
# ==================================================================

# -----------------------------------------
# Execute System Command
# -----------------------------------------
sub process_command {

  my $temp_string = $EMPTY;
  my $t0          = time ();

  printf { *STDOUT } ( "\n%s\n", $command );

  my @args             = ( $command );
  my $systemReturncode = system ( @args );

  # The return value is the exit status of the program as returned by the wait call.
  # To get the actual exit value, shift right by eight (see below).
  if ( $systemReturncode != 0 ) {
    print { *STDERR } ( "\nWarning: system($command) failed: $?\n" );

    if ( $systemReturncode == -1 ) {
      printf { *STDERR } ( "Failed to execute: $!\n" );
    }
    elsif ( $systemReturncode & 127 ) {
      $temp_string = sprintf ( 
        "Child died with signal %d, %s coredump\n", 
        ( $systemReturncode & 127 ), 
        ( $systemReturncode & 128 ) ? 'with' : 'without' 
      );
      printf { *STDERR } $temp_string;
    }
    else {
      $temp_string = sprintf ( "Child exited with value %d\n", $systemReturncode >> 8 );
      printf { *STDERR } $temp_string;
    }
  }

  my $t1 = time ();

  my $elapsed          = $t1 - $t0;
  my $actionReturncode = $systemReturncode >> 8;
  printf { *STDERR } ( "\nElapsed, System-RC, Action-RC: $elapsed, $systemReturncode, $actionReturncode\n" );

  return $systemReturncode;
}


# -----------------------------------------
# Trim whitespaces from the start and end of the string.
# -----------------------------------------
sub trim {

  my $string = shift;

  $string =~ s/^\s+//;
  $string =~ s/\s+$//;

  return ( $string );
}


# -----------------------------------------
# Copy directory recursively
# -----------------------------------------
sub copy_dir_rec {

  my $src_dir = shift;
  my $dst_dir = shift;

  mkpath "$dst_dir"
    unless -d "$dst_dir";

  die "unable to copy directory: Source $src_dir not a directory\n"
     unless -d $src_dir;
  die "unable to copy directory: Destination $dst_dir not a directory\n"
     unless -d $dst_dir;

  chdir $src_dir;
  
  find( sub {
    # $_ is just the filename, "test.txt"
    # $File::Find::name is the full "/path/to/the/file/test.txt".
    # we could filter here for specific files, but we don't
    #return if $_ !~ /\.txt$/i;
    return unless -f;   # We want files only
    mkpath "$dst_dir/$File::Find::dir" 
      unless -d "$dst_dir/$File::Find::dir";
    copy "$_", "$dst_dir/$File::Find::dir"
      or die "Can't copy the file $File::Find::name...";
  }, ".");

  return;
}


# -----------------------------------------
# Remove existing WORK and INSTALL Directories
# -----------------------------------------
sub purge_dirs {

  printf { *STDOUT } ( "\n" );

  # Remove the existing directories
  rmtree ( "$WORKDIR",    0, 1 );
  rmtree ( "$WORKDIRLANG",0, 1 );
  rmtree ( "$INSTALLDIR", 0, 1 );

  sleep 1;

  # Verzeichnisstrukturen neu anlegen
#  mkpath ( "$WORKDIR" );
#  mkpath ( "$WORKDIRLANG" );
#  mkpath ( "$INSTALLDIR" );

  printf { *STDOUT } ( "\n" );

  return;
}

# -----------------------------------------
# Create the needed WORK and INSTALL Directories
# -----------------------------------------
sub create_dirs {

  printf { *STDOUT } ( "\n" );

  # Remove the existing directories
  # (WORKDIR to be handled differently lateron ?)
#  rmtree ( "$WORKDIR",    0, 1 );
#  rmtree ( "$WORKDIRLANG",0, 1 );
#  rmtree ( "$INSTALLDIR", 0, 1 );

  sleep 1;

  # Create the directories if needed (
  # WORKDIR is needed for all types of map
  if ( !(-e $WORKDIR ) ) {
    mkpath ( "$WORKDIR" );
  }    
  
  # WORKDIRLANG and INSTALLDIR only needed for final map, not for downloaded regions we use for own extracts only
  # (In case someone builds a parent map, directory creation is forced anyway)
  if ( ( $maptype != 1 ) || ( $actionlangdir eq 'yes' ) ){
     if ( !(-e $WORKDIRLANG ) ) {
       mkpath ( "$WORKDIRLANG" );
     }    
     if ( !(-e $INSTALLDIR ) ) {
       mkpath ( "$INSTALLDIR" );
     }
  }    

  printf { *STDOUT } ( "\n" );

  return;
}

# -----------------------------------------
# Check if all download URLs are existing
# -----------------------------------------
sub check_downloadurls {

  my $returnvalue;

  # Set the OS specific command
  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $command = "curl --output /dev/null --silent --fail --head --url ";
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/wget/windows/wget.exe -q --spider ";
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
  }

  # run through the complete maps array
  for my $mapdata ( @maps ) {
	
	# Jump to next it's not a real map
#	if ( ( @$mapdata[ $MAPID ] == -1 ) || ( @$mapdata[ $OSMURL ] eq "NA" ) ) {
	if ( @$mapdata[ $MAPID ] == -1 ) {
		next;
    }

    # Real map, print out a header per map
    print "\n" . @$mapdata[ $MAPNAME ] . "\n";
    print "---------------------------------------------------\n";

    # Check the MapURL for map types 1 and 3 (downloadable OSM data extracts)
    if ( ( @$mapdata[ $MAPTYPE ] == 1 ) || ( @$mapdata[ $MAPTYPE ] == 3 ) ) {
		# Map with downloadable OSM data extract
        $returnvalue = system( $command . @$mapdata[ $OSMURL ]);
        if ( $returnvalue != 0 ) {
    		print "FAIL: OSM:   ";
    	}
    	else {
    		print "OK:   OSM:   ";
        }
        print @$mapdata[ $OSMURL ] ."\n";	
	}
	else {
		# No OSM Data to download, will be extracted by script
		print "N/A:  OSM:   (this map doesn't need downloadable OSM Data)\n";
	}
	
    # Check the MapURL for map types 2 and 3 (downloadable elevation data)
    if ( ( @$mapdata[ $MAPTYPE ] == 2 ) || ( @$mapdata[ $MAPTYPE ] == 3 ) ) {
        # Check the ElevationData 10m
        $returnvalue = system( $command . "$elevationbaseurl{ele10}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" );
        if ( $returnvalue != 0 ) {
    		print "FAIL: ele10: ";
    	}
    	else {
    		print "OK:   ele10: ";
        }
        print "$elevationbaseurl{ele10}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" . "\n";  
    
        # Check the ElevationData 20m
        $returnvalue = system( $command . "$elevationbaseurl{ele20}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" );
        if ( $returnvalue != 0 ) {
    		print "FAIL: ele20: ";
    	}
    	else {
    		print "OK:   ele20: ";
        }
        print "$elevationbaseurl{ele20}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" . "\n";  
    
#        # Check the ElevationData 25m
#        $returnvalue = system( $command . "$elevationbaseurl{ele25}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" );
#        if ( $returnvalue != 0 ) {
#    		print "FAIL: ele25: ";
#    	}
#    	else {
#    		print "OK:   ele25: ";
#        }
#        print "$elevationbaseurl{ele25}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" . "\n";      
	}
	else {
		# No elevation Data to download, we don't need it
		print "N/A:  ele10: (this map doesn't need downloadable elevation Data)\n";		
		print "N/A:  ele20: (this map doesn't need downloadable elevation Data)\n";		
#		print "N/A:  ele25: (this map doesn't need downloadable elevation Data)\n";		
	}
	  
  }
	
  print "\n\n";
  
}

# -------------------------------------------
# Check single URL Routine
# -------------------------------------------
sub check_url {

  my $download_src = shift;

  my $returnvalue;
  my $url_valid = 1;

  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $command = "curl --output /dev/null --silent --fail --head --url \"$download_src\"";

  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/wget/windows/wget.exe -q --spider \"$download_src\"";

  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }
  
  # Run the command
  $returnvalue = system( $command );
  if ( $returnvalue != 0 ) {
 	$url_valid = 0;
  }

 
  # Return the status
  return ( $url_valid );

}


# -------------------------------------------
# Download URL Routine (used in other places)
# -------------------------------------------
sub download_url {

  my $download_src = shift;
  my $download_dst = shift;

  # Initialize the default verbosity (no downloadbar) and other options
  my $downloadbar_wget = "-nv";
  my $downloadbar_curl = "--silent";
  my $download_continue_wget = "";
  my $download_continue_curl = "";
  my $downloadspeed_wget = "";
  my $downloadspeed_curl = "";

  # Check if option was used to show downloadbar
  if ( $downloadbar ) {
    $downloadbar_wget = "";
    $downloadbar_curl = "";
  }
  
  # Fetch option continuedownload (not allowed for bootstrap to avoid possible manual intervention)
  if ( $actionname ne 'bootstrap' && ( $continuedownload )  ) {
    $download_continue_wget = "--continue";
    $download_continue_curl = "-C -";
  }

  # Check for specific downloadspeed set
  if ( $downloadspeed ) {
    $downloadspeed_wget = "--limit-rate=$downloadspeed";
    $downloadspeed_curl = "--limit-rate $downloadspeed";
  }


  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $command = "curl $downloadbar_curl $download_continue_curl $downloadspeed_curl --fail --location --url \"$download_src\" --output \"$download_dst\" --write \"Downloaded %{size_download} bytes in %{time_connect} seconds (%{speed_download} bytes/s)\"";
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/wget/windows/wget.exe $downloadbar_wget $download_continue_wget $downloadspeed_wget --output-document=\"$download_dst\" \"$download_src\"";
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }
  
  # Run the command
  process_command ( $command );
  
  # Return the status
  return ( $? );

}


# -----------------------------------------
# Download OSM map data from the Internet
# -----------------------------------------
sub fetch_osmdata {

  my $filename = "$WORKDIR/Kartendaten_$mapname.osm.pbf";

  # Check for existence of WORKDIR
  if ( !( -e $WORKDIR ) ) {
    die ( "\nERROR:\nThe directory $WORKDIR is missing.\nDid you run the Action 'create' for creating the necessary directories ?\n\n" );
  }
  
  download_url ( $osmurl, $filename );
  
  if ( $? != 0 ) {
      die ( "ERROR:\n  download of osm data from $osmurl failed.\n\n" );
  }  

  # auf gültige osm.pbf-Datei prüfen
  if ( !check_osmpbf ( $filename ) ) {
    printf { *STDERR } ( "\nError: File <$filename> is not a valid osm.pbf file.\n" );
    die ( "Please check this file concerning error hints (eg. communications errors).\n" );
    return ( 1 );
  }

  return;
}


# -----------------------------------------
# Download elevation data from the internet
# -----------------------------------------
sub fetch_eledata {

  my $filename = "$WORKDIR/Hoehendaten_$mapname.osm.pbf";

  # Check for existence of WORKDIR
  if ( !( -e $WORKDIR ) ) {
    die ( "\nERROR:\nThe directory $WORKDIR is missing.\nDid you run the Action 'create' for creating the necessary directories ?\n\n" );
  }    

  # Download-URL
  my $eleurl = '';
  if ( $ele == 10 ) {
     if ( $hqele ) {
	    $eleurl = "$hqelevationbaseurl{ele10}/Hoehendaten_$mapname.osm.pbf";
	 }
     else {
        $eleurl = "$elevationbaseurl{ele10}/Hoehendaten_$mapname.osm.pbf";
	 }	 
  }
  elsif ( $ele == 20 ) {
     if ( $hqele ) {
	    $eleurl = "$hqelevationbaseurl{ele20}/Hoehendaten_$mapname.osm.pbf";
	 }
     else {
        $eleurl = "$elevationbaseurl{ele20}/Hoehendaten_$mapname.osm.pbf";
	 }	 
  }
  else {
    # Default = 25 Meter
    # $eleurl = "$elevationbaseurl{ele25}/Hoehendaten_$mapname.osm.pbf";
    die ( "ERROR:\n  elevation data: unsupported constant contour value of $ele choosen.\n\n" );
  }

   download_url( $eleurl, $filename);

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  download of elevation data from $eleurl failed.\n\n" );
  }
  
  # auf gültige osm.pbf-Datei prüfen
  if ( !check_osmpbf ( $filename ) ) {
    printf { *STDERR } ( "\nError: File <$filename> is not a valid osm.pbf file.\n" );
    die ( "Please check this file concerning error hints (eg. communications errors).\n" );
    return ( 1 );
  }
  
  # Try to fetch the additional file *.info
  if ( check_url( "$eleurl.info" ) ) {
     download_url( "$eleurl.info", "$filename.info");
  }
  else {
      printf { *STDERR } ( "\nINFORMATION: $eleurl.info not existing.\n" );
  }

  # Try to fetch the additional file *.license  
  if ( check_url ( "$eleurl.license" ) ) {
      download_url ( "$eleurl.license", "$filename.license");
  }
  else {
      printf { *STDERR } ( "\nINFORMATION: $eleurl.license not existing.\n" );
  }

  return;
}


# -----------------------------------------
# Read a given local licensefile into hash
# -----------------------------------------
sub read_licensefile {

  # Argument handed over
  my $licensefile = shift;
  
  # Some needed local variables
  my $line;
  my @alllines;
  my %tmphash = ();
  my $tmphash_key;
  my $tmphash_value;
  
  # Let's try to open 
  if ( open IN,  "<:encoding(UTF-8)", $licensefile ) {

    binmode( IN, ":encoding(UTF-8)");

    
    while ( <IN> ) {
      # Get the line
      $line = $_;
      
      # Only look at lines with '=' somewhere in the middle
      next unless $line =~ /^.*=.*+/;
      
      # Get rid of leading and trailing whitespace
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      
      # Put result in the prepared input array
      chomp ( $line );
      push ( @alllines, $line );
      
    }
    
    # Close the file again
    close IN;
    
    # run through the array and fill the tmphash
    foreach $line ( @alllines ) {
      # create the hashtable
      $line =~ /^(.*)=(.*)$/;      
      $tmphash{ $1 } = join( "\n", split ( /\\n/, $2 ));
      
    }
    
  }
  
  return ( %tmphash );

}

# -----------------------------------------
# Read the default license information
# -----------------------------------------
sub read_default_licenses {

  # Set filenames
  my $fzk_licensefile = "$BASEPATH/licenses/default-freizeitkarte.license";
  my $osm_licensefile = "$BASEPATH/licenses/default-osm.license";
  my $ele_licensefile = "$BASEPATH/licenses/default-elevation.license";
    
  # Handle fzk license file
  my %lic_tmphash = ();
  %lic_tmphash = read_licensefile($fzk_licensefile);
  foreach my $hashkey ( sort ( keys %lic_tmphash ) ) {
    $lic_fzk{$hashkey} = $lic_tmphash{$hashkey};
  }
  
  # Handle osm license file
  %lic_tmphash = ();
  %lic_tmphash = read_licensefile($osm_licensefile);
  foreach my $hashkey ( sort ( keys %lic_tmphash ) ) {
    $lic_osm{$hashkey} = $lic_tmphash{$hashkey};
  }

  # Handle ele license file
  %lic_tmphash = ();
  %lic_tmphash = read_licensefile($ele_licensefile);
  foreach my $hashkey ( sort ( keys %lic_tmphash ) ) {
    $lic_ele{$hashkey} = $lic_tmphash{$hashkey};
  }


  return;

}

# -----------------------------------------
# Try to update the license about elevation
# -----------------------------------------
sub update_ele_license {

  # Argument handed over
  my $ele_licensefile = "$WORKDIR/Hoehendaten_$mapname.osm.pbf.license";
    
  # Some needed local variables
  my %ele_tmphash = ();
  
  # Get eventually overriding values
  %ele_tmphash = read_licensefile($ele_licensefile);
  
  # In case we have updates
  if ( keys %ele_tmphash > 0 ) {
    
    # Set strongest flag to 0
    $lic_ele{license_type_strongest} = "";

    # Override (or set) found values
    foreach my $hashkey ( sort ( keys %ele_tmphash ) ) {
      $lic_ele{$hashkey} = $ele_tmphash{$hashkey};
    }
  
  }

  # If license type of ele is strongest, then override fzk license type
  if ( $lic_ele{license_type_strongest}) {
    $lic_fzk{license_type} = $lic_ele{license_type};
  }


  return;

}


# -----------------------------------------
# Check osm ids for potential conflicts (gives nasty artefacts in map)
# -----------------------------------------
sub check_osmid {

  # change the directory
  chdir "$WORKDIR";

  # Initialize some variables
  my $filename_kartendaten  = "$WORKDIR/Kartendaten_$mapname.osm.pbf";
  my $available_kartendaten = 0;
  my $filename_hoehendaten  = "$WORKDIR/Hoehendaten_$mapname.osm.pbf";
  my $available_hoehendaten = 0;
  my $cmdpath = "";
  my $cmdoutput = "";
  my $osm_nid_min = "";
  my $osm_nid_max = "";
  my $osm_wid_min = "";
  my $osm_wid_max = "";
  my $ele_nid_min = "";
  my $ele_nid_max = "";
  my $ele_wid_min = "";
  my $ele_wid_max = "";
  my $osm_idcheck_ok = "1";
  my $osm_idcheck_remark = "";

  # check if the osm map file exists and has the proper format
  if ( -e $filename_kartendaten ) {
    if ( check_osmpbf ( $filename_kartendaten ) ) {
      $available_kartendaten = 1;
    }
  }

  if ( -e $filename_hoehendaten ) {
    # check if the elevation data exists and has the proper format
    if ( check_osmpbf ( $filename_hoehendaten ) ) {
      $available_hoehendaten = 1;
    }
  }

  # All there and so far ok, let's continue
  if ( $available_kartendaten && $available_hoehendaten ) {

    printf { *STDERR } ( "\nChecking map and elevation data for overlapping osm IDs...\n" );

    # Create the basepath, depending OS
    if ( $OSNAME eq 'darwin' ) {
      # OS X
      $cmdpath = "$BASEPATH/tools/osmconvert/osx/osmconvert";
    }	
    elsif ( $OSNAME eq 'MSWin32' ) {
      # Windows
      $cmdpath = "$BASEPATH\\tools\\osmconvert\\windows\\osmconvert.exe";
    }
    elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
      # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
      if ( ( $OSNAME eq 'linux' ) && ( $os_archbit eq '64' ) ) {
        $cmdpath = "$BASEPATH/tools/osmconvert/linux/osmconvert64";
      }
      else
      {
        $cmdpath = "$BASEPATH/tools/osmconvert/linux/osmconvert32";
      }
      
    }

    # Get the statistics of the map data
    $cmdoutput = `$cmdpath ${filename_kartendaten} --out-statistics 2>&1`;

    # Try to match the different things
    if ( $cmdoutput =~ /^node id min: (.*)$/m ) {
	     $osm_nid_min = $1;
    }
    if ( $cmdoutput =~ /^node id max: (.*)$/m ) {
	     $osm_nid_max = $1;
#       $osm_nid_max = 8500000000;
    }
    if ( $cmdoutput =~ /^way id min: (.*)$/m ) {
	     $osm_wid_min = $1;
    }
    if ( $cmdoutput =~ /^way id max: (.*)$/m ) {
	     $osm_wid_max = $1;
#       $osm_wid_max = 8500000000;
    }

    # Get the statistics of the map ele
    $cmdoutput = `$cmdpath ${filename_hoehendaten} --out-statistics 2>&1`;

    # Try to match the different things
    if ( $cmdoutput =~ /^node id min: (.*)$/m ) {
	     $ele_nid_min = $1;
    }
    if ( $cmdoutput =~ /^node id max: (.*)$/m ) {
	     $ele_nid_max = $1;
    }
    if ( $cmdoutput =~ /^way id min: (.*)$/m ) {
	     $ele_wid_min = $1;
    }
    if ( $cmdoutput =~ /^way id max: (.*)$/m ) {
	     $ele_wid_max = $1;
    }

    # Let's print the IDs, even if something is wrong with them
    printf { *STDERR } ( " Map: node id min: %15s\n" , $osm_nid_min ); 
    printf { *STDERR } ( " Map: node id max: %15s\n" , $osm_nid_max ); 
    printf { *STDERR } ( " Ele: node id min: %15s\n" , $ele_nid_min ); 
    printf { *STDERR } ( " Ele: node id max: %15s\n" , $ele_nid_max ); 
    printf { *STDERR } ( "\n" ); 
    printf { *STDERR } ( " Map: way id min:  %15s\n" , $osm_wid_min ); 
    printf { *STDERR } ( " Map: way id max:  %15s\n" , $osm_wid_max ); 
    printf { *STDERR } ( " Ele: way id min:  %15s\n" , $ele_wid_min ); 
    printf { *STDERR } ( " Ele: way id max:  %15s\n" , $ele_wid_max ); 
    printf { *STDERR } ( "\n" ); 

    # Check if all IDs could be set
    # Map data
    if ( $osm_nid_min eq "" || $osm_nid_max eq "" || $osm_wid_min eq "" || $osm_wid_max eq "") {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "At least one ID of the map data is invalid\n";
    }
    # Ele data
    if ( $ele_nid_min eq "" || $ele_nid_max eq "" || $ele_wid_min eq "" || $ele_wid_max eq "") {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "At least one ID of the ele data is invalid\n";
    }

    # Stop here if something is wrong already
    if ( $osm_idcheck_ok == 0 ) {
       die ( "\nError: OSM ID conflict check: $mapcode\n${osm_idcheck_remark}\n" );
       return ( 1 );
    }
    
    # Check if any of the IDs is zero or negative (should not happen ?)
    # Map data
    if ( $osm_nid_min <= 0 || $osm_nid_max <= 0 || $osm_wid_min <= 0 || $osm_wid_max <= 0) {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "At least one ID of the map data is either zero or negative\n";
    }
    # Ele data
    if ( $ele_nid_min <= 0 || $ele_nid_max <= 0 || $ele_wid_min <= 0 || $ele_wid_max <= 0) {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "At least one ID of the ele data is either zero or negative\n";
    }

    # Stop here if something is wrong already
    if ( $osm_idcheck_ok == 0 ) {
       die ( "\nError: OSM ID conflict check: $mapcode\n${osm_idcheck_remark}\n" );
       return ( 1 );
    }

    # Check for overlapping ID ranges
    # Node IDs
    if ( ! ( ( ( $osm_nid_min < $osm_nid_max ) and ( $osm_nid_max < $ele_nid_min ) and ( $ele_nid_min < $ele_nid_max ) ) xor ( ( $ele_nid_min < $ele_nid_max ) and ( $ele_nid_max < $osm_nid_min ) and ( $osm_nid_min < $osm_nid_max ) ) ) ) {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "We have potential conflicts with the node id values\n";
    }
    # Way IDs
    if ( ! ( ( ( $osm_wid_min < $osm_wid_max ) and ( $osm_wid_max < $ele_wid_min ) and ( $ele_wid_min < $ele_wid_max ) ) xor ( ( $ele_wid_min < $ele_wid_max ) and ( $ele_wid_max < $osm_wid_min ) and ( $osm_wid_min < $osm_wid_max ) ) ) ) {
        $osm_idcheck_ok = "0";
        $osm_idcheck_remark = $osm_idcheck_remark . "We have potential conflicts with the way id values\n";
    }

    # Stop here if something is wrong already else let user know that all seems to be ok
    if ( $osm_idcheck_ok == 0 ) {
#    printf { *STDERR } ( "${osm_idcheck_remark}" ); 
       die ( "\nError: OSM ID conflict check: $mapcode\n${osm_idcheck_remark}\n" );
       return ( 1 );
    }
    else {
       printf { *STDERR } ( "\nOK: OSM ID conflict check: $mapcode\nno potential conflicts found\n\n" ); 
    }
    

  }

  return;
}


# -----------------------------------------
# Join osm map data and elevation data into a complete map
# -----------------------------------------
sub join_mapdata {

  # change the directory
  chdir "$WORKDIR";

  # Initialize some variables
  my $filename_kartendaten  = "$WORKDIR/Kartendaten_$mapname.osm.pbf";
  my $available_kartendaten = 0;
  my $filename_hoehendaten  = "$WORKDIR/Hoehendaten_$mapname.osm.pbf";
  my $available_hoehendaten = 0;
  my $filename_ergebnisdaten = "$WORKDIR/$mapname.osm.pbf";

  # check if the osm map file exists and has the proper format
  if ( -e $filename_kartendaten ) {
    if ( check_osmpbf ( $filename_kartendaten ) ) {
      $available_kartendaten = 1;
    }
  }

  if ( -e $filename_hoehendaten ) {
    # check if the elevation data exists and has the proper format
    if ( check_osmpbf ( $filename_hoehendaten ) ) {
      $available_hoehendaten = 1;
    }
  }

  # All there and so far ok, let's continue
  if ( $available_kartendaten && $available_hoehendaten ) {

    printf { *STDERR } ( "\nJoining map and elevation data ...\n" );

    # Make sure that the Java options are brought into the osmosis call
    my $javacmd_options = '-Xmx' . $javaheapsize . 'M';
    $ENV{ JAVACMD_OPTIONS } = $javacmd_options;

    # Put the osmosis parameter together
    my $osmosis_parameter = 
        " --read-pbf $filename_kartendaten" 
      . " --read-pbf $filename_hoehendaten" 
      . " --merge" 
      . " --write-pbf $filename_ergebnisdaten" 
      . " omitmetadata=true";

    if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
      # OS X, Linux, FreeBSD, OpenBSD
      $command = "sh $BASEPATH/tools/osmosis/bin/osmosis $osmosis_parameter";
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
      # Windows
      $command = "$BASEPATH/tools/osmosis/bin/osmosis.bat $osmosis_parameter";
    }
    else {
      die ( "\nFehler: Operating system $OSNAME not supported.\n" );
      return ( 1 );
    }
    
    # run the command
    process_command ( $command );
      
    # Check Return Value
    if ( $? != 0 ) {
        die ( "ERROR:\n  Joining map and elevation data for $mapname failed.\n\n" );
    }
    
  }
  elsif ( $available_kartendaten ) {
    # only mapdata there, elevation stuff missing, but let's continue anyway
    printf { *STDERR } ( "\nWarning: Elevation data file <$filename_hoehendaten> not found.\n" );
    printf { *STDERR } ( "\nCopying map data ...\n" );

    # so let's copy mapdata only
    copy ( $filename_kartendaten, $filename_ergebnisdaten ) or die ( "copy() failed: $!\n" );
  }
  else {
    # no map data and no elevation data available
    die ( "\nError: Map data file <$filename_kartendaten> not found.\n" );
    return ( 1 );
  }

  return;
}


# -----------------------------------------
# Split the map into tiles
# -----------------------------------------
sub split_mapdata {
  
  # Intialize variables
  my $filename_ergebnisdaten = "$WORKDIR/$mapname.osm.pbf";

  # Check if the file exists and has proper format
  if ( -e $filename_ergebnisdaten ) {
    if ( !check_osmpbf ( $filename_ergebnisdaten ) ) {
      die ( "\nError: Resulting data file <$filename_ergebnisdaten> is not a valid osm.pbf file.\n" );
      return ( 1 );
    }
  }
  else {
    die ( "\nError: Resulting data file <$filename_ergebnisdaten> does not exists.\n" );
    return ( 1 );
  }

# Call of split eventually to be changes with one or several of below options
#  . " --no-trim" 
#  . " --ignore-osm-bounds"
#  . " --polygon-file=something.poly"


#
  # split the map
  $command = 
     "java -Xmx" 
   . $javaheapsize . "M" 
   . " -jar $BASEPATH/tools/splitter/splitter.jar" 
   . $max_threads 
   . " --geonames-file=$BASEPATH/cities/cities15000.zip" 
   . " --no-trim"
   . " --precomp-sea=$BASEPATH/sea" 
   . " --keep-complete=true" 
   . " --mapid=" 
   . $mapid . "0001" 
   . " --max-nodes=800000" 
   . " --output=xml" 
   . " --output-dir=$WORKDIR $filename_ergebnisdaten";
  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Spliting the map $mapname into tiles failed.\n\n" );
  }

  return;
}


# -----------------------------------------
# Create the map specific license file needed by mkgmap
# -----------------------------------------
sub create_licensefile {

  # Initialize some variables
  my $filename = "$WORKDIRLANG/$mapname.license";

  # Dump some output
  printf { *STDOUT } ( "\n" );
  printf { *STDOUT } ( "Creating $filename ...\n" );
  
  # Try to open the file in destination codepage (isocode)
#  open ( my $fh, "+>:encoding($mapisolang)", $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
#  binmode( $fh, ":encoding($mapisolang)");
  open ( my $fh, "+>:encoding(UTF-8)", $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
  binmode( $fh, ":encoding(UTF-8)");
      
  # Empty line (copyright-file issue)
  printf { $fh } ("\n" );

  # New: 3 line of licenses
  printf { $fh } ("(c) %s: %s (%s)\n", 
    $lic_fzk{'title_short'}, 
    $lic_fzk{'license_string_short'},
    $lic_fzk{'license_type'} 
    );
  printf { $fh } ("(c) %s: %s (%s)\n", 
    $lic_osm{'title_short'}, 
    $lic_osm{'license_string_short'},
    $lic_osm{'license_type'} 
    );
  printf { $fh } ("(c) %s: %s (%s)\n", 
    $lic_ele{'title_short'}, 
    $lic_ele{'license_string_short'},
    $lic_ele{'license_type'} 
    );

  # Try to close the file again
  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );
  
  
  return;
}


# -----------------------------------------
# Create the map specific license file needed by nsis
# -----------------------------------------
sub create_licensefile_nsis {

  # Initialize some variables
  my $filename_de = "$WORKDIRLANG/$mapname.nsis.license.de";
  my $filename_en = "$WORKDIRLANG/$mapname.nsis.license.en";
  # Reverse file assignement in order to check German Umlaute for EN Map like LUX (for tests)
  #my $filename_de = "$WORKDIRLANG/$mapname.nsis.license.en";
  #my $filename_en = "$WORKDIRLANG/$mapname.nsis.license.de";

  # Dump some output
  printf { *STDOUT } ( "\n" );
  
  # Try to open the files for writing (always in Latin1 as we support only german and english in the installer)
  printf { *STDOUT } ( "Creating $filename_de  ...\n" );
  open ( my $fh_de, '+>', $filename_de ) or die ( "Can't open $filename_de: $OS_ERROR\n" );
  #open ( my $fh_de, '+>:encoding(iso-8859-1)', $filename_de ) or die ( "Can't open $filename_de: $OS_ERROR\n" );
  #binmode( $fh_de, ":encoding(iso-8859-1)");

printf { *STDOUT } ( "Creating $filename_en  ...\n" );
  open ( my $fh_en, '+>', $filename_en ) or die ( "Can't open $filename_en: $OS_ERROR\n" );
  #open ( my $fh_en, '+>:encoding(iso-8859-1)', $filename_en ) or die ( "Can't open $filename_en: $OS_ERROR\n" );
  #binmode( $fh_en, ":encoding(iso-8859-1)");


  # DE: Use
  printf { $fh_de }
    (   "%s\n\n", 
      $lic_fzk{'use_de'} );
  # EN: Use
  printf { $fh_en }
    (   "%s\n\n", 
      $lic_fzk{'use_en'} );

  # DE: Help
  printf { $fh_de }
    (   "%s\n\n", 
      $lic_fzk{'help_de'} );
  # EN: Help
  printf { $fh_en }
    (   "%s\n\n", 
      $lic_fzk{'help_en'} );

  # DE: License map
  printf { $fh_de }
    (   "%s:\n"
      . "Lizenztyp: %s\n"
      . "Von: %s\n"
      . "Name: %s\n"
      . "Webseite: %s\n" 
      . "%s\n\n", 
      $lic_fzk{'title_long_de'},
      $lic_fzk{'license_type'}, 
      $lic_fzk{'license_string_short'}, 
      $lic_fzk{'data_provider_name'},
      $lic_fzk{'data_provider_homepage'},
      $lic_fzk{'additional_info_de'} 
      );

  # EN: License map
  printf { $fh_en }
    (   "%s:\n"
      . "Licensetype: %s\n"
      . "By: %s\n"
      . "Name: %s\n"
      . "Link: %s\n" 
      . "%s\n\n", 
      $lic_fzk{'title_long_en'},
      $lic_fzk{'license_type'}, 
      $lic_fzk{'license_string_short'}, 
      $lic_fzk{'data_provider_name'},
      $lic_fzk{'data_provider_homepage'},
      $lic_fzk{'additional_info_en'} 
      );

  # DE: License OSM
  printf { $fh_de }
    (   "%s:\n"
      . "Lizenztyp: %s\n"
      . "Von: %s\n"
      . "Name: %s\n"
      . "Webseite: %s\n"
      . "%s\n\n", 
      $lic_osm{'title_long_de'},
      $lic_osm{'license_type'}, 
      $lic_osm{'license_string_short'}, 
      $lic_osm{'data_provider_name'},
      $lic_osm{'data_provider_homepage'},
      $lic_osm{'additional_info_de'} );
  # EN: License OSM
  printf { $fh_en }
    (   "%s:\n"
      . "Licensetype: %s\n"
      . "By: %s\n"
      . "Name: %s\n"
      . "Link: %s\n"
      . "%s\n\n", 
      $lic_osm{'title_long_de'},
      $lic_osm{'license_type'}, 
      $lic_osm{'license_string_short'}, 
      $lic_osm{'data_provider_name'},
      $lic_osm{'data_provider_homepage'},
      $lic_osm{'additional_info_en'} );

  # DE: License Contour data
  printf { $fh_de }
    (   "%s:\n"
      . "Lizenztyp: %s\n"
      . "Von: %s\n"
      . "Name: %s\n"
      . "Webseite: %s\n"
      . "%s\n\n", 
      $lic_ele{'title_long_de'},
      $lic_ele{'license_type'}, 
      $lic_ele{'license_string_short'}, 
      $lic_ele{'data_provider_name'},
      $lic_ele{'data_provider_homepage'},
      $lic_ele{'additional_info_de'} );
  # EN: License Contour data
  printf { $fh_en }
    (   "%s:\n"
      . "Licensetype: %s\n"
      . "By: %s\n"
      . "Name: %s\n"
      . "Link: %s\n"
      . "%s\n\n", 
      $lic_ele{'title_long_en'},
      $lic_ele{'license_type'}, 
      $lic_ele{'license_string_short'}, 
      $lic_ele{'data_provider_name'},
      $lic_ele{'data_provider_homepage'},
      $lic_ele{'additional_info_en'} );

  # Try to close the files again
  close ( $fh_de ) or die ( "Can't close $filename_de: $OS_ERROR\n" );
  close ( $fh_en ) or die ( "Can't close $filename_en: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );

  return;
}


# -----------------------------------------
# Create the map specific CFG file needed by mkgmap
# - Note that option order is significant.
# - An option only applies to subsequent input files.
# -----------------------------------------
sub create_cfgfile {

  # Initialize some variables
  my $filename = "$WORKDIRLANG/$mapname.cfg";

  # Dump some output
  printf { *STDOUT } ( "\n" );
  printf { *STDOUT } ( "Creating $filename ...\n" );
  
  # Try to open the file
#  open ( my $fh, '+>', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
  open ( my $fh, "+>:encoding(UTF-8)", $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
  binmode( $fh, ":encoding(UTF-8)");

  # Write the needed options into the file
  printf { $fh } 
    (   "# ------------------------------------------------------------------------------\n" 
      . "# Zweck   : mkgmap-Konfigurationsdatei\n" 
      . "# Version : " 
      . $VERSION . "\n" 
      . "# Erzeugt : " 
      . localtime () . "\n" 
      . "# ------------------------------------------------------------------------------\n" );

  printf { $fh } ( "\n# General options:\n" );
  printf { $fh } ( "# ---------------\n" );

  # printf { $fh }
  #   (   "\n"
  #     . "# --coastlinefile=filename[,filename]\n"
  #     . "#   Defines a comma separated list of files that contain coastline\n"
  #     . "#   data. The coastline data from the input files are removed if\n"
  #     . "#   this option is set. Files must have OSM or PBF fileformat.\n"
  #     . "coastlinefile: $BASEPATH/coasts/coastlines.osm.pbf\n" );

  printf { $fh } 
    (   "\n" 
      . "# --precomp-sea=directoryname\n" 
      . "#   Defines the directory that contains the precompiled sea tiles.\n" 
      . "#   When this option is defined all natural=coastline tags from the\n" 
      . "#   input OSM tiles are removed and the precompiled data is used instead.\n" 
      . "#   This option can be combined with the generate-sea options\n" 
      . "#   multipolygon, polygons and land-tag. The coastlinefile option\n" 
      . "#   is ignored if precomp-sea is set.\n" 
      . "precomp-sea=$BASEPATH/sea\n" );

  printf { $fh } 
    (   "\n" 
      . "# --description=text\n" 
      . "#   Sets the descriptive text for the map. This may be displayed in\n" 
      . "#   QLandkarte, MapSource or on a GPS etc, where it is normally shown\n" 
      . "#   below the family name. Example: --description=\"Germany, Denmark\"\n" 
      . "#   Please note: if you use splitter.jar to build a template.args file\n" 
      . "#   an use -c template.args, then that file may contain a\n" 
      . "#   \"description\" that will override this option. Use \"--description\" in\n" 
      . "#   splitter.jar to change the description in the template.args file.\n" 
      . "description=\"%s (Release %s)\"\n", 
    $mapname, 
    $releasestring 
  );

  printf { $fh } ( "\n# Label options:\n" );
  printf { $fh } ( "# -------------\n" );

  printf { $fh } 
    (   "\n" 
      . "# --latin1\n" 
      . "#   This is equivalent to --code-page=1252.\n" 
      . "# latin1\n" 
      . "code-page=" . $mapcodepage . "\n" );
      
  printf { $fh }
    (   "\n"
      . "# --name-tag-list=list"
      . "#   Changes the tag that will be used to supply the name, normally it is just 'name'.\n"
      . "#   Useful for language variations. You can supply a list and the first one will be used.\n"
      . "#   Example: --name-tag-list=name:en,int_name,name\n" );
  if ( $nametaglist ne $EMPTY ) {
     printf { $fh }    
        (   "name-tag-list=$nametaglist\n" );  
  }
  else {
     printf { $fh }    
        (   "#name-tag-list=name:de,name:en,int_name,name\n" );
  }
  
  printf { $fh } 
  (   "\n" 
    . "# --lower-case\n" 
    . "#   Allow labels to contain lower case letters.\n" 
    . "#   Note that most or all Garmin devices are not able to display\n" 
    . "#   lower case letters at an angle so this option is not generally useful.\n" 
    . "lower-case\n" );

  printf { $fh } ( "\n# Address search options:\n" );
  printf { $fh } ( "# ----------------------\n" );

  printf { $fh } 
    (   "\n" 
      . "# --index\n" 
      . "#   Generate a global index that can be used with MapSource.\n" 
      . "#   Makes the find places functions in MapSource available.\n" 
      . "#   The index consists of two files named osmmap.mdx and osmmap_mdr.img\n" 
      . "#   by default.  The overview-mapname can be used to change the name.\n" 
      . "#   If the mapset is sent to the device from MapSource, it will enable\n" 
      . "#   find by name and address search on the GPS.\n" 
      . "index\n" );

  printf { $fh } 
    (   "\n" 
      . "# --split-name-index\n"
      . "#   Index each part of a street name separately. For example, if the street is \n"
	  . "#   \"Aleksandra Gryglewskiego\" then you will be able to search for it as both \n"
	  . "#   \"Aleksandra\" and \"Gryglewskiego\". It will also increase the size of the index.\n"
	  . "#   Useful in countries where searching for the first word in name is not the right\n"
	  . "#   thing to do. Words following an opening bracket '(' are ignored.\n" 
	  . "split-name-index\n" );

  printf { $fh } 
    (   "\n" 
      . "# --road-name-config=filename\n"
      . "#   Provide the name of a file containing commonly used road name prefixes and \n"
	  . "#   suffixes. This option handles the problem that some countries have road names \n"
	  . "#   which often start or end with very similar words, e.g. in France the first word \n"
	  . "#   is very often 'Rue', often followed by a preposition like 'de la' or 'des'. This \n"
	  . "#   leads to rather long road names like 'Rue de la Concorde' where only the word \n"
	  . "#   'Concorde' is really interesting. In the USA, you often have names like \n"
	  . "#   'West Main Street' where only the word 'Main' is important. Garmin software has some \n"
	  . "#   tricks to handle this problem. It allows the use of special characters in the road \n"
	  . "#   labels to mark the beginning and end of the important part. In combination with option \n"
	  . "#   split-name-index only the words in the important part are indexed.\n"
      . "#road-name-config=$BASEPATH/searchoptions/roadNameConfig.txt\n" );

  printf { $fh }
    (   "\n"
      
	  . "# --bounds=directory\n"
      . "#   The directory that contains the preprocessed bounds files.\n"
      . "#   Default: bounds\n"
      . "bounds=$BASEPATH/bounds\n" );

  printf { $fh }
    (   "\n"
      . "# --location-autofill=[option1,[option2]]\n"
      . "#   Controls how country, region, city and zip info is gathered for\n"
      . "#   cities, streets and pois.\n"
      . "#   Default: bounds\n"
      . "#\n"
      . "#   bounds  The preprocessed boundaries are used to mark all points,\n"
      . "#           lines and polygons within a boundary with the special tag:\n"
      . "#           mkgmap:admin_level2 : Name of the admin_level=2 boundary\n"
      . "#           mkgmap:admin_level3 : Name of the admin_level=3 boundary\n"
      . "#           ..\n"
      . "#           mkgmap:admin_level11\n"
      . "#           mkgmap:postcode : the postal_code value\n"
      . "#\n"
      . "#           The style file can be used to assign the address tags mkgmap:country,\n"
      . "#           mkgmap:region etc. with these values.\n" . "#\n"
      . "#   is_in   The is_in tag is analyzed for country and region information.\n"
      . "#           This is done only for address tags that are not defined by the\n"
      . "#           style rules.\n"
      . "#\n"
      . "#   nearest If all methods before fail the city/hamlet points that are\n"
      . "#           closest to the element are used to assign the missing address tags.\n"
      . "#           Warning: elements may end up in the wrong country/region/city.\n"
      # . "location-autofill=bounds,is_in,nearest\n" );
      . "location-autofill=is_in,nearest\n" );

  printf { $fh }
     (   "\n"
       . "#--housenumbers\n"
       . "#  Enables house number search for OSM input files.\n"
       . "#  All nodes and polygons having addr:housenumber and addr:street set are matched\n"
       . "#  to streets. A match between house number element and street is created if\n"
       . "#  the street is located within a radius of 150m and the addr:street tag of the\n"
       . "#  house number element\n"
       . "#    - equals the mgkmap:street tag of the street. mkgmap:streets should be set\n"
       . "#      in the style file.\n"
       . "#    - or it equals the name of the street stripped by garmin shields and all text\n"
       . "#      within round brackets.\n"
       . "#  Example:\n"
       . "#     Node -  addr:street=Main Street addr:housenumber=2\n"
       . "#     Way 1 - mkgmap:street=Main Street\n"
       . "#     Way 2 - name=Main Street (A504)\n"
       . "#     Way 3 - mkgmap:street=Mainstreet\n"
       . "#     Way 4 - name=Main Street [A504]\n"
       . "#    The node matches to way 1 and way 2 but not to way 3 (does not equal exactly)\n"
       . "#    and not to way 4 (only text in round brackets is ignored)\n"
       . "housenumbers\n" );

  printf { $fh } ( "\n# Overview map options:\n" );
  printf { $fh } ( "# ---------------------\n" );

  printf { $fh } (
    "\n"
      . "# --overview-mapname=name\n"
      . "#   If --tdbfile is enabled, this gives the name of the overview\n"
      . "#   .img and .tdb files. The default map name is osmmap.\n"
      . "overview-mapname=%s\n",
      $mapname );

  printf { $fh }
    (   "\n"
      . "# --overview-mapnumber=8 digit number\n"
      . "#   If --tdbfile is enabled, this gives the internal 8 digit\n"
      . "#   number used in the overview map and tdb file. The default\n"
      . "#   number is 63240000.\n"
      . "overview-mapnumber=%s0000\n",
      $mapid );

  printf { $fh }
    (   "\n"
      . "#--overview-levels\n"
      . "#  like levels, specifies additional levels that are to be written to the\n"
      . "#  overview map. Counting of the levels should continue. Up to 8 additional\n"
      . "#  levels may be specified, but the lowest usable resolution with MapSource\n"
      . "#  seems to be 11. The hard coded default is empty.\n"
      );

  printf { $fh }
    (   "\n"
      . "#--remove-ovm-work-files\n"
      . "#  If overview-levels is used, mkgmap creates one additional file\n"
      . "#  with the prefix ovm_ for each map (*.img) file.\n"
      . "#  These files are used to create the overview map.\n"
      . "#  With option --remove-ovm-work-files=true the files are removed\n"
      . "#  after the overview map was created. The default is to keep the files.\n"
      . "#remove-ovm-work-files\n" );

  printf { $fh } ( "\n# Style options:\n" );
  printf { $fh } ( "# -------------\n" );

  printf { $fh }
    (   "\n"
      . "# --style-file=file\n"
      . "#   Specify an external file to obtain the style from.  \'file\' can\n"
      . "#   be a directory containing files such as info, lines, options\n"
      . "#   (see resources/styles/default for an example).  The directory\n"
      . "#   path must be absolute or relative to the current working\n"
      . "#   directory when mkgmap is invoked.\n"
      . "style-file=$WORKDIRLANG/$mapstyledir\n" );

  printf { $fh } ( "\n# Product description options:\n" );
  printf { $fh } ( "# ---------------------------\n" );

  printf { $fh }
    (   "\n" 
      . "# --family-id\n"
      . "#   This is an integer that identifies a family of products.\n" 
      . "family-id=%s\n",
      $mapid );

  printf { $fh }
    (   "\n"
      . "# --family-name\n"
      . "#   If you build several maps, this option describes the\n"
      . "#   family name of all of your maps. Garmin will display this\n"
      . "#   in the map selection screen.\n"
      . "family-name=%s\n",
      $mapname );

  printf { $fh }
    (   "\n"
      . "# --product-id\n"
      . "#   This is an integer that identifies a product within a family.\n"
      . "#   It is often just 1, which is the default.\n"
      . "product-id=1\n" );

  # Beispiel: 11.07 = 1107; 1107 / 100 = 11; 1107 % 100 = 7;
  printf { $fh }
    (   "\n" 
      . "# --product-version\n" 
      . "#   The version of the product. Default value is 1.\n" 
      . "product-version=%d\n",
      $releasenumeric );

  printf { $fh } (
    "\n"
      . "# --series-name\n"
      . "#   This name will be displayed in MapSource in the map selection\n"
      . "#   drop-down. The default is \"OSM map\".\n"
      . "series-name=%s\n",
      $mapname );

  printf { $fh }
    (   "\n"
      . "# --copyright-message=note\n"
      . "#   Specify a copyright message for files that do not contain one.\n"
      . "#copyright-message = \"Map: %s; Map Data: %s; Contour Data: %s\"\n", 
      $lic_fzk{'license_string_short'}, $lic_osm{'license_string_short'}, $lic_ele{'license_string_short'} );

  printf { $fh }
    (   "\n"
      . "# --copyright-file=file\n"
      . "#   Specify copyright messages from a file.\n"
      . "#   Note that the first copyright message is not displayed on a device, but is shown in BaseCamp.\n"
      . "#   The copyright file must include at least two lines.\n"
      . "copyright-file=%s.license\n",
      $mapname );

  printf { $fh }
    (   "\n"
      . "# --license-file=file\n"
      . "#   Specify a file which content will be added as license. Every\n"
      . "#   line is one entry. All entrys of all maps will be merged, unified\n"
      . "#   and shown in random order.\n"
      . "license-file=%s.license\n", 
      $mapname );

  printf { $fh } ( "\n# Optimization options:\n" );
  printf { $fh } ( "# --------------------\n" );

  printf { $fh } ( "\n# Miscellaneous options:\n" );
  printf { $fh } ( "# ---------------------\n" );

  printf { $fh }
    (   "\n"
      . "# --route\n"
      . "#   Experimental: Create maps that support routing. This implies --net\n"
      . "#   (so that --net need not be given if --route is given).\n"
      . "route\n" );

  printf { $fh }
    (   "\n"
      . "# --drive-on-left\n"
      . "# --drive-on-right\n"
      . "#   Explicitly specify which side of the road vehicles are\n"
      . "#   expected to drive on. If neither of these options are\n"
      . "#   specified, it is assumed that vehicles drive on the right\n"
      . "#   unless --check-roundabouts is specified and the first\n"
      . "#   roundabout processed is clockwise.\n"
      . "drive-on-right\n" );

  printf { $fh }
    (   "\n"
      . "# --preserve-element-order\n"
      . "#   Process the map elements (nodes, ways, relations) in the order\n"
      . "#   in which they appear in the OSM input. Without this option,\n"
      . "#   the order in which the elements are processed is not defined.\n"
      . "preserve-element-order\n" );

  printf { $fh }
    (   "\n"
      . "# --remove-short-arcs[=MinLength]\n"
      . "#   Merge nodes to remove short arcs that can cause routing\n"
      . "#   problems. If MinLength is specified (in metres), arcs shorter\n"
      . "#   than that length will be removed. If a length is not\n"
      . "#   specified, only zero-length arcs will be removed.\n"
      . "#remove-short-arcs=3\n" );

  printf { $fh }
    (   "\n"
      . "# --adjust-turn-headings[=BITMASK]\n"
      . "#   Where possible, ensure that turns off to side roads change\n"
      . "#   heading sufficiently so that the GPS believes that a turn is\n"
      . "#   required rather than a fork. This also avoids spurious\n"
      . "#   instructions to \"keep right/left\" when the road doesn\'t\n"
      . "#   actually fork.\n"
      . "adjust-turn-headings\n" );

  printf { $fh }
    (   "\n"
      . "# --add-pois-to-areas\n"
      . "#   Generate a POI for each area. The POIs are created after the\n"
      . "#   style is applied and only for polygon types that have a\n"
      . "#   reasonable point equivalent.\n"
      . "add-pois-to-areas\n" );

  printf { $fh }
    (   "\n"
      . "# --generate-sea[=ValueList]\n"
      . "#   Generate sea polygons. ValueList is an optional comma\n"
      . "#   separated list of values:\n"
      . "#\n"
      . "# multipolygon\n"
      . "#   generate the sea using a multipolygon (the default\n"
      . "#   behaviour so this really doesn't need to be specified).\n"
      . "#\n"
      . "# no-sea-sectors\n"
      . "#   disable the generation of \"sea sectors\" when the\n"
      . "#   coastline fails to reach the tile's boundary.\n"
      . "#\n"
      . "# extend-sea-sectors\n"
      . "#   same as no-sea-sectors. Additional adds a point so\n"
      . "#   coastline reaches the nearest tile boundary.\n"
      . "#\n"
      . "# land-tag=TAG=VAL\n"
      . "#   tag to use for land polygons (default natural=land).\n"
      . "#\n"
      . "# close-gaps=NUM\n"
      . "#   close gaps in coastline that are less than this distance (metres)\n"
      # . "generate-sea:multipolygon,no-sea-sectors,extend-sea-sectors,close-gaps=5000,land-tag=natural=land\n" );
      . "generate-sea=land-tag=natural=land\n" );

  printf { $fh }
    (   "\n"
      . "# --link-pois-to-ways\n"
      . "#   If this option is enabled, POIs that are situated at a point\n"
      . "#   in a way will be associated with that way and may modify the\n"
      . "#   way's properties. Currently supported are POIs that restrict\n"
      . "#   access (e.g. bollards). Their access restrictions are applied\n"
      . "#   to a small region of the way near the POI.\n"
      . "link-pois-to-ways\n" );

  printf { $fh } 
    (   "\n" 
      . "# --tdbfile\n" 
      . "#   Write a .tdb file.\n" 
      . "tdbfile\n" );

  printf { $fh }
    (   "\n"
      . "# --show-profiles=1\n"
      . "#   Sets a flag in tdb file which marks set mapset as having contour\n"
      . "#   lines and allows showing profile in MapSource. Default is 0\n"
      . "#   which means disabled.\n"
      . "show-profiles=1\n" );

  if ( $dempath ne $EMPTY ) {
     printf { $fh }
       (   "\n"
         . "# --dem\n" 
         . "# The option expects a comma separated list of paths to directories or zip\n"
         . "# files containing *.hgt files. Directories are searched for *.hgt files and\n"
         . "#  also for *.hgt.zip and *.zip files.\n"
         . "# The list is searched in the given order, so if you want to use 1'' files\n"
         . "# make sure that they are found first. There are different sources for *.hgt\n"
         . "# files, some have so called voids which are areas without data.\n"
         . "# Those should be avoided.\n"
         . "dem=%s\n", $dempath );
     printf { $fh }
       (   "\n"
         . "# --dem-poly=filename\n" 
         . "# If given, the filename should point to a *.poly file in osmosis polygon file\n"
         . "# format. The polygon described in the file is used to determine the area for\n"
         . "# which DEM data should be added to the map. If not given, the DEM data\n"
         . "# will cover the full tile area.\n"
         . "dem-poly=%s.poly\n", "$BASEPATH/poly/$mapname" );
     if ( $demdists ne $EMPTY ) {
	    printf { $fh }
          (   "\n"
            . "# --dem-dists=number[,number...]\n"
	        . "# Details see: http://www.mkgmap.org.uk/doc/options\n"
            . "dem-dists=%s\n", $demdists );
        }
	 }

  printf { $fh }
    (   "\n" 
      . "# --verbose\n" 
      . "#   Makes some operations more verbose. Mostly used with --list-styles.\n" 
      . "verbose\n" );

#  printf { $fh }
#    (   "\n" 
#      . "# --x-housenumbers\n"
#      . "#   Housenumbers that are tagged with addr:housenumber and addr:street are now\n"
#      . "#   applied. It can be enabled with the undocumented parameter --x-housenumbers.\n"
#      . "#   It's not yet an official parameter because it handles only a small\n"
#      . "# subset of housenumbers.\n"
#      . "x-housenumbers\n" );

  # Add the tiles
  # Kartenkacheln anhaengen
  # mapname: 58100003
  # description: DE-Konstanz
  # input-file: 58100003.osm.gz

  printf { $fh } ( "\n# Following the list of map tiles:\n" );
  printf { $fh } ( "# -------------------------------\n\n" );

  my $filename_tiles = "$WORKDIR/template.args";
  open ( my $fh_tiles, '<', $filename_tiles ) or die ( "Can't open $filename_tiles: $OS_ERROR\n" );
  my ( @lines ) = <$fh_tiles>;
  close ( $fh_tiles );

  foreach my $line ( @lines ) {
    my ( $identifier, $rest ) = split ( /:/, $line, 2 );

    if ( $identifier eq 'mapname' ) {
      printf { $fh } ( "%s", $line );
    }

    if ( $identifier eq 'description' ) {
      printf { $fh } ( "%s: %s%s", $identifier, $releasestring, $rest );
    }

    if ( $identifier eq 'input-file' ) {
	  $rest =~ s/^\s+//;
      printf { $fh } ( "%s: %s/%s\n", $identifier, $WORKDIR, $rest );
    }
  }

  # -- no more options after that line / hier keine Optionen anfügen --

  # Try to close the file again
  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );

  return;
}

# -----------------------------------------
# Create all different possible TYP files (all per language)
# -----------------------------------------
sub create_alltypfile_languages {
  
  # Initialize Variables
  # --------------------
  my $typfileworkdir    = "$BASEPATH/work/typfiles";
  my $typfileinstalldir = "$BASEPATH/install/typfiles";
  
  # Purge the directories if needed
  # -------------------------------
  if ( -e "$typfileworkdir" ) {
    rmtree ( "$typfileworkdir", 0, 1 );
  }
  if ( -e "$typfileinstalldir" ) {
    rmtree ( "$typfileinstalldir",    0, 1 );
  }

  # Recreate them again
  # ---------------------------------
  mkpath ( "$typfileworkdir" );
  mkpath ( "$typfileinstalldir" );
   
  # Loop through all supported languages
  # ----------------------------------
  for my $actuallanguage ( @supportedlanguages )  {
    
    # Get the actual language code like 'en'
    $typfilelangcode = @$actuallanguage [$LANGCODE];
    $mapcodepage = $langcodepage{$typfilelangcode};

    # Create some output
    printf { *STDOUT } ( "\nHandling TYP files: $typfilelangcode\n" );
    printf { *STDOUT } ( "------------------------\n" );
    
    # Check for the existence of the main typfiles directories
    if ( !(-e "$typfileworkdir/$typfilelangcode" ) ) {
      mkpath ( "$typfileworkdir/$typfilelangcode" );
    }    
    if ( !(-e "$typfileinstalldir/$typfilelangcode" ) ) {
      mkpath ( "$typfileinstalldir/$typfilelangcode" );
    }    
    
    # Create the complete source files together with the translations
    create_typtranslations ();
    
    # Compile these source files into the final TYP files
    compile_typfiles ();
    
    # copy all compiled TYP files over to install directory
    chdir "$typfileworkdir/$typfilelangcode";
    for my $file ( <*.TYP> ) {
      printf { *STDOUT } ( "Copying %s\n", $file );
      copy ( $file, "$typfileinstalldir/$typfilelangcode" . "/" . $file ) or die ( "copy() $file failed: $!\n" );
    }

  }

}


# -----------------------------------------
# Create all different possible ReplaceTyp.zip files
# -----------------------------------------
sub create_allreplacetyp_languages {
  
  # Initialize Variables
  # --------------------
  my $typfileworkdir    = "$BASEPATH/work/typfiles";
  my $typfileinstalldir = "$BASEPATH/install/typfiles";
  
    
  # Loop through all supported languages
  # ----------------------------------
  for my $actuallanguage ( @supportedlanguages )  {
    
    # Get the actual language code like 'en'
    $typfilelangcode = @$actuallanguage [$LANGCODE];
    
    # Create some output
    printf { *STDOUT } ( "\nHandling ReplaceTyp: $typfilelangcode\n" );
    printf { *STDOUT } ( "--------------------------\n" );
    
    # Check for the existence of the main typfiles directories
    if ( !(-e "$typfileworkdir" ) ) {
      die ( "\nERROR:\nThe directory $typfileworkdir/$typfilelangcode is missing.\nDid you run the Action 'alltypfiles' to get all needed files ?\n\n" );
    }    
    if ( !(-e "$typfileinstalldir/$typfilelangcode" ) ) {
      die ( "\nERROR:\nThe directory $typfileinstalldir/$typfilelangcode is missing.\nDid you run the Action 'alltypfiles' to get all needed files ?\n\n" );
    }    

    # Create the needed ReplaceTyp directory
    # --------------------------------------
    if ( !(-e "$typfileworkdir/$typfilelangcode/ReplaceTyp" ) ) {
      mkpath ( "$typfileworkdir/$typfilelangcode/ReplaceTyp" );
    }    
    
    
    # Put the ReplaceTyp directory together
    # -------------------------------------
    # Skeleton (everything except the TYP files)
    chdir "$BASEPATH/tools/ReplaceTyp/";
    for my $file ( <*> ) {
      printf { *STDOUT } ( "Copying %s\n", $file );
      cp ( $file, "$typfileworkdir/$typfilelangcode/ReplaceTyp" . "/" . $file ) or die ( "copy() $file failed: $!\n" );
    }
    # TYP files
    chdir "$typfileworkdir/$typfilelangcode/";
    for my $file ( <*.TYP> ) {
      printf { *STDOUT } ( "Copying %s\n", $file );
      copy ( $file, "$typfileworkdir/$typfilelangcode/ReplaceTyp" . "/" . $file ) or die ( "copy() $file failed: $!\n" );
    }
    
    # Now zip the result
    # ------------------
    # Initialize some variables
    my $source      = $EMPTY;
    my $destination = $EMPTY;
    my $zipper      = $EMPTY;

    # get the needed tool (OS depending)
    if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
      # OS X, Linux, FreeBSD, OpenBSD
      $zipper = 'zip -r ';
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
      # Windows
      $zipper = $BASEPATH . '/tools/zip/windows/7-Zip/7za.exe a ';
    }
    else {
      die ( "\nError: Operating system $OSNAME not supported.\n" );
      return ( 1 );
    }

    # Put the command together
    $source      = 'ReplaceTyp';
    $destination = 'ReplaceTyp.zip';
    $command     = $zipper . "$destination $source";
    if ( -e $source ) {
      process_command ( $command );
    }

    # Copy the result to the install directory
    # ----------------------------------------
    copy ( "ReplaceTyp.zip", "$typfileinstalldir/$typfilelangcode/ReplaceTyp.zip" ) or die ( "copy() ReplaceTyp.zip failed: $!\n" );

  }  

}

# -----------------------------------------
# Deduct the file map specific 'typ-translations' containing all needed strings
# -----------------------------------------
sub create_typtranslations {
  
  # Attention: called from different places and reacting differently
  # (directories) depending on the action

  # Create some output (just to know where we are)
  print "\nCreating complete source txt files for the TYP files\n"
      . "  (containing all needed language strings)\n\n";
	

  # Short description of the process:
  # ---------------------------------
  # 1) deduct which languages will end up in the TYP files (max 4)
  # 2) Read all TYP file translations into hashes
  # 3) 'Mix-down': add the translations to the source TXT files

  # defined languages
  my %typlanguages = (
    "xx", "0x00",    #	 unspecified
    "fr", "0x01",    #	 french
    "de", "0x02",    #	 german
    "nl", "0x03",    #	 dutch
    "en", "0x04",    #	 english
    "it", "0x05",    #	 italian
    "fi", "0x06",    #	 finnish
    "sv", "0x07",    #	 swedish
    "es", "0x08",    #	 spanish
    "eu", "0x09",    #	 basque
    "ca", "0x0a",    #	 catalan
    "gl", "0x0b",    #	 galician
    "cy", "0x0c",    #	 welsh
    "gd", "0x0d",    #	 gaelic
    "da", "0x0e",    #	 danish
    "no", "0x0f",    #	 norwegian
    "pt", "0x10",    #	 portuguese
    "sk", "0x11",    #	 slovak
    "cs", "0x12",    #	 czech
    "hr", "0x13",    #	 croatian
    "hu", "0x14",    #	 hungarian
    "pl", "0x15",    #	 polish
    "tr", "0x16",    #	 turkish
    "el", "0x17",    #	 greek
    "sl", "0x18",    #	 slovenian
    "ru", "0x19",    #	 russian
    "et", "0x1a",    #	 estonian
    "lv", "0x1b",    #	 latvian
    "ro", "0x1c",    #	 romanian
    "sq", "0x1d",    #	 albanian
    "bs", "0x1e",    #	 bosnian
    "lt", "0x1f",    #	 lithuanian
    "sr", "0x20",    #	 serbian
    "mk", "0x21",    #	 macedonian
    "bg", "0x22"     #	 bulgarian
  );

  my %typlanguagesbyhex = reverse %typlanguages;

  # Set some Variables
  my $inputfile;
  my $outputfile;
  my $actualfile;

  my @typfilelangcode;
  my %typfilestringindex;
  my %typfilestringhex;
  my $stringindex = 1;

  my $langcode    = $EMPTY;
  # If we're building all typ file languages then use the variable $typfilelangcode
  if ( $alltypfile ) {
    $langcode = $typfilelangcode;
  }
  # Looks like we're building a normal map, so use $maplang
  else {
    $langcode = $maplang;
  }

  my $inputline;
  my $thisobjectform;
  my $thisobjecttype;
  my $thisobjectsubtype;
  my $thisobjectid;
  my $thisobjectstringhash;
  my $thisobjectstringsdone;
  my %thisobjectstrings  = ();
  my %objecttranslations = ();

  # 1) deduct which languages will end up in the TYP files (max 4)
  # -----------------------------------------------------------------------------
  # Create an array with the languages that go into the TYP files
  push ( @typfilelangcode, $typlanguages{ $langcode } );
  $typfilestringindex{ $typlanguages{ $langcode } } = $stringindex;
  $stringindex++;
  foreach my $tmp ( @typfilelangfixed ) {
    if ( ( $tmp ne $langcode ) && ( $stringindex le 4 ) && ( ( $langcodepage{$langcode} eq $langcodepage{$tmp} )  || ( $unicode ) ) ) {
      push ( @typfilelangcode, $typlanguages{ $tmp } );
      $stringindex++;
    }
  }


  # Fill the hash with the languages and the stringindex (properly sorted)
  $stringindex = 1;
  foreach my $hexcode ( sort ( keys %typlanguagesbyhex ) ) {
    foreach my $tmp ( @typfilelangcode ) {
      if ( $tmp eq $hexcode ) {
        $typfilestringindex{ $tmp } = $stringindex;
        $stringindex++;
      }
    }
  }
  %typfilestringhex = reverse %typfilestringindex;
  

  # 2) Read all TYP file translations into hashes
  # ----------------------------------------------
  # Open input
  $inputfile = "$BASEPATH/translations/typ-translations-master";
  open IN, "< $inputfile" or die "Can't open $inputfile : $!";

  # Read through the inputfile
  while ( <IN> ) {

    # Get the line and make sure that line endings are correct
    $inputline = $_;
    chomp ($inputline);
    $inputline =~ s/\r$//;    

    # empty the temporary variables
    $thisobjectform    = '';
    $thisobjecttype    = '';
    $thisobjectsubtype = '';
    $thisobjectid      = '';
    %thisobjectstrings = ();

    if ( $inputline =~ /^\[_(line|polygon|point)\]$/ ) {
      $thisobjectform = $1;

      # read nextline
      $inputline = <IN>;
      chomp($inputline);
      $inputline =~ s/\r$//;          
      $inputline =~ /^Type=(0x[0-9A-F]{2,5})/i;
      $thisobjecttype = $1;
      if ( $thisobjectform eq "point" ) {
        $inputline = <IN>;
        chomp($inputline);
        $inputline =~ s/\r$//;          
        $inputline =~ /^SubType=(0x[0-9A-F]{2,5})/i;
        $thisobjectsubtype = $1;
      }

      # Create the Object ID
      $thisobjectid = "$thisobjectform" . "_" . "$thisobjecttype" . "_" . "$thisobjectsubtype";

      # Get strings
      while ( <IN> ) {
        last if /^\[end\]/;    # Object finished, get on
        $inputline = $_;
        chomp($inputline);
        $inputline =~ s/\r$//;          
        # Check for strings
        if ( $inputline =~ /^String[0-9]*=(0x[0-9A-F]{2}),(.*)$/i ) {
          $thisobjectstringhash = $thisobjectid . "_$1";
          $objecttranslations{ $thisobjectstringhash } = $2;
        }
      }
    }
  }

  close IN;


  # 3) 'Mix-down': add the translations to the source TXT files
  #------------------------------------------------------------
  # Let's go to the TYP file directory to fetch all files
  chdir "$BASEPATH/TYP";

  # Run through all the source txt files found in the TYP directory
  for my $actualfile ( glob "*.txt" ) {

    $inputfile  = "$BASEPATH/TYP/$actualfile";
    #$outputfile = "$WORKDIR/TYP/$actualfile";
    #$outputfile = "$WORKDIRLANG/$actualfile";

    # If we're building all typ file languages we need a different output directory
    if ( $alltypfile ) {
      $outputfile = "$BASEPATH/work/typfiles/$langcode/$actualfile";
    }
    else {
      $outputfile = "$WORKDIRLANG/$actualfile";
    }

    open IN, "< $inputfile" or die "Can't open $inputfile : $!";
    #  open OUT, ">:encoding(UTF-8)","$outputfile" or die "Can't open $outputfile : $!";
    open OUT, ">:", "$outputfile" or die "Can't open $outputfile : $!";

    # Read through the inputfile
    while ( <IN> ) {

      # Get the line and make sure that line endings are correct
      $inputline = $_;
      chomp ($inputline);
      $inputline =~ s/\r$//;    

      # empty the temporary variables
      $thisobjectform        = '';
      $thisobjecttype        = '';
      $thisobjectsubtype     = '';
      $thisobjectid          = '';
      $thisobjectstringsdone = 0;
      %thisobjectstrings     = ();

      if ( $inputline =~ /^\[_(line|polygon|point)\]$/ ) {
        print OUT $inputline . "\n";

        $thisobjectform = $1;

        # read nextline
        $inputline = <IN>;
        chomp($inputline);
        $inputline =~ s/\r$//;          
        print OUT $inputline . "\n";

        $inputline =~ /^Type=(0x[0-9A-F]{2,5})/i;
        $thisobjecttype = $1;
        if ( $thisobjectform eq "point" ) {
          $inputline = <IN>;
          chomp($inputline);
          $inputline =~ s/\r$//;          
          print OUT $inputline . "\n";
          $inputline =~ /^SubType=(0x[0-9A-F]{2,5})/i;
          $thisobjectsubtype = $1;
        }

        # Create the Object ID
        $thisobjectid = "$thisobjectform" . "_" . "$thisobjecttype" . "_" . "$thisobjectsubtype";

        # Get strings
        while ( <IN> ) {
          $inputline = $_;
          chomp($inputline);
          $inputline =~ s/\r$//;          

          # Check for strings
          if ( $inputline =~ /^String[0-4]*=(0x[0-9A-F]{2},.*)$/i ) {
            if ( $thisobjectstringsdone == 0 ) {
              for my $tmp ( sort ( keys ( %typfilestringhex ) ) ) {
                $thisobjectstringsdone = 1;
                $thisobjectstringhash  = $thisobjectid . "_$typfilestringhex{$tmp}";
                if ( defined $objecttranslations{ $thisobjectstringhash } ) {
                  print OUT "String$tmp=$typfilestringhex{$tmp}," . $objecttranslations{ $thisobjectstringhash } . "\n";
                }
                else {
                  print "WARNING: $actualfile: string with ID $thisobjectstringhash not defined in the translation file\n";
                  $thisobjectstringsdone = 0;
                  print OUT $inputline . "\n";
                  last;
                }
              }
            }
          }
          elsif ( $inputline =~ /^\[end\]/ ) {
            print OUT $inputline . "\n";
            last;
          }
          else {
            print OUT $inputline . "\n";
          }
        }
      }
 
      # we have to filter out and adapt some strings inside the [_id] section
      elsif ( $inputline =~ /^\[_(id)\]$/ ) {
	     print OUT $inputline . "\n";	 
	     
        # Get strings
        while ( <IN> ) {
          $inputline = $_;
          chomp($inputline);
          $inputline =~ s/\r$//;          

          # Check for strings
          if ( $inputline =~ /^ProductCode=.*$/i ) {
		     print OUT "ProductCode=1\n";
          }
          elsif ( $inputline =~ /^FID=.*$/i ) {
		     print OUT "FID=$mapid\n";
          }
          elsif ( $inputline =~ /^CodePage=.*$/i ) {
            # We need to handle that differently if we run alltypfile: $mapcodepage does not exist then
            if ( $alltypfile ) {
              print OUT "CodePage=$langcodepage{$langcode}\n";
            }
            else {
              print OUT "CodePage=$mapcodepage\n";
            } 
          }
          elsif ( $inputline =~ /^\s*\[end\]/i ) {
            print OUT $inputline . "\n";
            last;
          }
          else {
            print OUT $inputline . "\n";
          }
        }

	      
	  }
      else {
        print OUT $inputline . "\n";
      }
    }

    close IN;
    close OUT;

  }
}


# -----------------------------------------
# Compilation of TYP files out of txt source files
# -----------------------------------------
sub compile_typfiles {
	

  # Create some output (just to know where we are)
  print "\nCompiling source txt files into binary TYP files:\n\n";
	

  # Jump to correct directory
#  chdir "$WORKDIR/TYP";
  chdir "$BASEPATH/TYP";
  my @typfilelist = glob "*.txt" ;

  # If we're building all typ file languages then we have to jump to a different directory
  if ( $alltypfile ) {
    chdir "$BASEPATH/work/typfiles/$typfilelangcode";
    # Set $mapid to something less problematic than -1
    $mapid=9999;
  }
  # Looks like we're building a normal map, so jump to the normal $WORKDIRLANG
  else {
    chdir "$WORKDIRLANG";
  }


  
  # Run through the existing textfiles
  for my $thistypfile ( @typfilelist ) {

    # run that file through the compiler
    $command = "java -Xmx" . $javaheapsize . "M" . " -Dfile.encoding=UTF-8 -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs --code-page=$mapcodepage --product-id=1 --family-id=$mapid $thistypfile";
 
    # Run the compiler
    process_command ( $command );
    
    # Check Return Value
    if ( $? != 0 ) {
        die ( "ERROR:\n  Compilation of $thistypfile failed.\n\n" );
    }

    # Rename .typ to .TYP
    move(basename("$thistypfile", ".txt") . ".typ" , basename("$thistypfile", ".txt" ) . ".TYP" ) or die ( "ERROR:\n  rename of $thistypfile failed.\n\n" ) ;

  }

  # Remove unneeded generated files
  unlink ( "osmmap.tdb" );
  unlink ( "osmmap.img" );
  
  return;
}

# -----------------------------------------
# Create map specific TYP file
# -----------------------------------------
sub create_typfile {

  # Jump to the correct directory
  chdir "$WORKDIRLANG";

  # copy TYP-File
  copy ( "$maptypfile.TYP", "$WORKDIRLANG/$mapid.TYP" ) or die ( "copy() of $maptypfile.TYP failed: $!\n" );

  return;
}


# -----------------------------------------
# Create map specific 'style-translations' file containing all needed strings
# -----------------------------------------
sub create_styletranslations {

  # Set some Variables
  my $inputfile  = "$BASEPATH/translations/style-translations-master";
  my $outputfile = "$WORKDIRLANG/style-translations";
  # fill $langcode with UpperCase of $maplang
  my $langcode   = "\U$maplang";
  my @input;
  my %translation = ();
  my $hashkey;
  my $line;

  # Open input and output files
  open IN,  "< $inputfile"  or die "Can't open $inputfile : $!";
  open OUT, "> $outputfile" or die "Can't open $outputfile : $!";

  # Read only the #define values from the file (ignoring trailing and tailing whitespace)
  while ( <IN> ) {
    # Get the line
    $line = $_;

    # Skip everything except the #define lines
    next unless $line =~ /^\s*\#define\s+/;

    # Get rid of leading and trailing whitespace
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    # Put result in the prepared input array
    chomp ( $line );
    push ( @input, $line );
  }

  # run through sorted array(to have defines without langcode above those with langcode)
  foreach $line ( sort ( @input ) ) {
    # Remove the wished langcode if existing
    $line =~ s/^(\#define \$__.*__)($langcode)\s+(.*)/$1 $3/;

    # Skip all the other language codes, just leave stuff without langcode
    next unless $line =~ /^\#define \$__.*__\s+.*/;

    # create the hashtable
    $line =~ /^\#define \$(__.*__)\s+(.*)$/;
    $translation{ $1 } = "$2";
  }

  # Write the output file
  foreach $hashkey ( sort ( keys %translation ) ) {
    print OUT "#define \$$hashkey $translation{$hashkey}\n";
  }

  # Close input and output files again
  close IN;
  close OUT;

}


# -----------------------------------------
# Prepare the style files: running through the PPP preprocessor
#
# ppp supports the following standard preprocessor features:
# #define %var% [value]
# #define %pseudo_fn%([arg-list])
# #undef %var%
# #include "path"
# #ifdef %var% .. #else .. #endif
# #ifndef %var% .. #else .. #endif
# #if <expr> .. #else .. #endif
# Macro variable expansion
#
# Usage: ppp <input-filename> [<output-filename>] [<options>]
#     where <options> =
#      -D<var>                   #define <var>
#      -D<var>=<value>           #define <var> with value <value>
#      -expand         or  -x    Expand all macros, includes and #ifdef
#      -expanddef      or  -xd   Expand #define-d macros only
#      -includeonly    or  -i    Expand #include only
#      -optdef         or  -od   Only process #define in -opt file
#      -opt=<file>               Process option file before others
#      -delete=<var>   or  -del  Delete code under #ifdef <var>
#      -inplace                  Edit files in-place, destructively
#      -debug[=<level>]          Run in debug mode
#      -list           or  -l    Create list file in TEMP dir as 'pplisting.txt'
#      -listfn         or  -lf   Display filename when showing line number
#      -verbose[=<n>]  or  -v    Set message level to 2 or <n>
#      -quiet          or  -q    Turn off all messages
#      -h                        Display splash header
# -----------------------------------------
sub preprocess_styles {

  # Since we support several styles with subdirectories we copy the complete selected style dir recursively
  copy_dir_rec("$BASEPATH/$mapstyledir", "$WORKDIRLANG/$mapstyledir");

  # Create list of *.master files to be handled via PPP
  my @masterfiles = ();
  chdir "$BASEPATH/$mapstyledir";
  find( sub{
    # $_ is just the filename, "test.txt"
    # $File::Find::name is the full "/path/to/the/file/test.txt".
    # we could filter here for specific files, but we don't
    return if $_ !~ /-master$/;
    return unless -f;   # We want files only
    push @masterfiles, $File::Find::name;
  }, ".");

  # Dump and exit
#  print Dumper @masterfiles;
#  exit;
  
  # Go to the Workdir LANG
#  chdir "$WORKDIRLANG";

  # Put the Options for the PPP preprocessor together (options that are given behind mapname)
  # $ARGV[ 0 ]                = Aktion;
  # $ARGV[ 1 ]                = Karte oder ID;
  # $ARGV[ 2 ] ... $ARGV[ N ] = Preprozessor-Optionen
  my $ppp_optionen = '';
  foreach my $argnum ( 2 .. $#ARGV ) {
    $ppp_optionen .= "-$ARGV[$argnum] ";
  }
  # Add the Preprozessor Option for the language
  $ppp_optionen .= "\U-D$maplang";

  # Loop through the list of *-master files 
  # (sorted to have a reproducible order of sequence independant on filesystem and platform)
  for my $masterfile ( sort @masterfiles ) {
    
    # Go to the correct directory
    my $masterfilepath = dirname($masterfile);
    print "\n\nPPP handling of: $mapstyledir/$masterfile";
    chdir "$WORKDIRLANG/$mapstyledir/$masterfilepath";
    
    # create the proper filenames
    my $masterfilename = basename($masterfile);
    my $newfilename = $masterfilename;
    $newfilename =~ s/-master$//;
    
    # Copy the style-translations to the actual directory
    copy("$WORKDIRLANG/style-translations", "$WORKDIRLANG/$mapstyledir/$masterfilepath");
    
    # Put the preprocessor command together and run it
    $command = "perl  $BASEPATH/tools/ppp/ppp.pl $masterfilename $newfilename -x $ppp_optionen";
    process_command ( $command );
    
  }

  return;

}


# -----------------------------------------
# Build the map
# -----------------------------------------
sub build_map {

  # change to directory WORKDIR LANG
  chdir "$WORKDIRLANG";
  
  # Try to update license info for elevation data
  update_ele_license;

  # create the licence file
  create_licensefile;
  
  # run mkgmap to build the map from the OSM data (-Dlog.config=logging.properties) (with checking style files first with --check-styles)
  $command = "java -Xmx" . $javaheapsize . "M" . " -Dfile.encoding=UTF-8 -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs -c $mapname.cfg --check-styles";
  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Creating the map $mapname with mkgmap failed.\n\n" );
  }

  return;
}


# -----------------------------------------
# Garmin-Map-File für BaseCamp erzeugen.
# Tool : gmapi-builder.py
# OS   : OS X
# -----------------------------------------
sub create_gmap2file {

  if ( $OSNAME ne 'darwin' and $OSNAME ne 'linux') {
    printf { *STDERR } ( "\nError: Function only on OS X and linux possible.\n" );
    return;
  }

  # in work-Verzeichnis wechseln
  chdir "$WORKDIRLANG";

  # Gmapi-Datei erzeugen
  $command =
      "$BASEPATH/tools/gmapi-builder/gmapi-builder.py" . " -v"
    . " -o $INSTALLDIR"
    . " -t $mapname.tdb"
    . " -s $mapid.TYP"
    . " -i $mapname.mdx"
    . " -m $mapname"
    . "_mdr.img"
    . " -b $mapname.img"
    . " $mapid*.img";
  process_command ( $command );

  return;
}


# -----------------------------------------
# Create the NSI file needed for compiling the Windows Installer
# (old style installer including ImageDir Set)
# -----------------------------------------
sub create_nsis_nsi_full {

  # Jump into the correct directory
  chdir "$WORKDIRLANG";

  # Get all TYP files
  my @typfiles = ( glob ( "*.TYP" ) );
  for my $thistypfile ( @typfiles ) {
    printf { *STDOUT } ( "TYP-File = $thistypfile\n" );
  }

  # Set and show the family-ID
  #my $familyID = substr ( $typfiles[ 0 ], 0, 4 );
  my $familyID = $mapid;
  printf { *STDOUT } ( "Family-ID = $familyID\n" );

  # Get and show imagefile names
  my @imgfiles = glob ( $familyID . "*.img" );
  for my $imgfile ( @imgfiles ) {
    printf { *STDOUT } ( "IMG-File = $imgfile\n" );
  }

  printf { *STDOUT } ( "Ausgabe %s\n", $releasestring );

  # Create output
  my $filename = $mapname . ".nsi";
  printf { *STDOUT } ( "\nCreating $filename ...\n" );

  # open ( my $fh, '+>:encoding(UTF-8)', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
  open ( my $fh, '+>', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );

  printf { $fh } ( "; ------------------------------------------------------------\n" );
  printf { $fh } ( "; Skript  : %s.nsi\n", $mapname );
  printf { $fh } ( "; Version : $VERSION\n" );
  printf { $fh } ( "; Erzeugt : %s\n", scalar ( localtime () ) );
  printf { $fh } ( ";\n" );
  printf { $fh } ( "; Bemerkungen:\n" );
  printf { $fh } ( "; - Kopieren der Kartendateien\n" );
  printf { $fh } ( "; - Eintragen der Windows-Registry-Keys für die Kartennutzung\n" );
  printf { $fh } ( "; - Eintragen der Windows-Registry-Keys für die Deinstallation\n" );
  printf { $fh } ( "; - Kopieren des Deinstallationsprogramms\n" );
  printf { $fh } ( "; ------------------------------------------------------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; General Settings\n" );
  printf { $fh } ( "; ----------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installationsverzeichnis (Default)\n" );
  printf { $fh } ( "!define INSTALLATIONS_VERZEICHNIS \"C:\\Freizeitkarte\\%s\"\n", $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Beschreibung der Karte\n" );
  printf { $fh } ( "!define KARTEN_BESCHREIBUNG \"%s\"\n", $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Ausgabe der Karte\n" );
  printf { $fh } ( "!define KARTEN_AUSGABE \"(Ausgabe %s)\"\n", $releasestring );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name der Installer-EXE-Datei\n" );
  printf { $fh } ( "!define INSTALLER_EXE_NAME \"Install_%s_%s\"\n", $mapname, $maplang );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name der Karte\n" );
  printf { $fh } ( "!define MAPNAME \"%s\"\n",     $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Product-ID der Karte\n" );
  printf { $fh } ( "!define PRODUCT_ID \"1\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name des Windows-Registrierungsschlüssels\n" );
  printf { $fh } ( "!define REG_KEY \"%s\"\n",     $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name des alten Windows-Registrierungsschlüssels (vor Umbenennung der Karten)\n" );
  printf { $fh } ( "!define REG_KEY_OLD \"%s\"\n", $mapnameold );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name des kartenspezifischen TYP-Files\n" );
  printf { $fh } ( "!define TYPNAME \"%s\"\n",     $typfiles[ 0 ] );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Compressor Settings\n" );
  printf { $fh } ( "; -------------------\n" );
  printf { $fh } ( "SetCompress off\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Include Modern UI\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!include \"MUI2.nsh\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Interface Settings\n" );
  printf { $fh } ( "; ------------------\n" );
  printf { $fh } ( "!define MUI_LANGDLL_ALLLANGUAGES\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installer Pages\n" );
  printf { $fh } ( "; ---------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"\$(INWpTitle)\"\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TEXT \"\$(INWpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"\$(INFpTitle)\"\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TEXT \"\$(INFpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_WELCOMEFINISHPAGE_BITMAP Install.bmp\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_WELCOME\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_LICENSE \$(licenseFile)\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_DIRECTORY\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_INSTFILES\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_FINISH\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Init Routine\n" );
  printf { $fh } ( "; ------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_CUSTOMFUNCTION_GUIINIT myGuiInit\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Uninstaller Pages\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"\$(UIWpTitle)\"\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TEXT \"\$(UIWpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"\$(UIFpTitle)\"\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TEXT \"\$(UIFpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_UNWELCOMEFINISHPAGE_BITMAP Deinstall.bmp\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_WELCOME\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_CONFIRM\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_INSTFILES\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_FINISH\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Language Settings\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!insertmacro MUI_LANGUAGE \"English\"\n" );
  printf { $fh } ( "!insertmacro MUI_LANGUAGE \"German\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString INWpTitle \${LANG_ENGLISH} \"Installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString INWpTitle \${LANG_GERMAN} \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString INWpText \${LANG_ENGLISH} \"This Wizard will be guiding you through the installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}.\$\\n\$\\nBefore installation BaseCamp must be closed for allowing installation of the map data.\$\\n\$\\nChoose Next for starting the installation.\"\n" );
  printf { $fh } ( "LangString INWpText \${LANG_GERMAN} \"Dieser Assistent wird Sie durch die Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor der Installation muss das Programm BaseCamp geschlossen werden damit Kartendateien ersetzt werden koennen.\$\\n\$\\nKlicken Sie auf Weiter um mit der Installation zu beginnen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LicenseLangString licenseFile \${LANG_ENGLISH} \"%s\"\n", "$mapname.nsis.license.en" );
  printf { $fh } ( "LicenseLangString licenseFile \${LANG_GERMAN} \"%s\"\n", "$mapname.nsis.license.de" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString INFpTitle \${LANG_ENGLISH} \"Installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} finished\"\n" );
  printf { $fh } ( "LangString INFpTitle \${LANG_GERMAN} \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh } ( "LangString INFpText \${LANG_ENGLISH} \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} has been succesfully installed on your computer.\$\\n\$\\nHave fun using the map.\$\\n\$\\nFor ensuring and increasing the quality of the map also your feedback is helpful (e.g. defects or improvements). Already now many thanks for it.\$\\n\$\\nChoose Finish to terminate the installation.\"\n" );
  printf { $fh } ( "LangString INFpText \${LANG_GERMAN} \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich auf Ihrem Computer installiert.\$\\n\$\\nViel Erfolg und Freude bei der Nutzung der Karte.\$\\n\$\\nUm die Qualitaet dieser Karte zu sichern und zu verbessern ist auch Ihr Feedback (z.B. zu Defekten oder Verbesserungen) hilfreich. An dieser Stelle schon einmal Danke hierfuer.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Installation abzuschliessen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString UIWpTitle \${LANG_ENGLISH} \"Deinstalling \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString UIWpTitle \${LANG_GERMAN} \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString UIWpText \${LANG_ENGLISH} \"This Wizard will be guiding you through the deinstallation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}.\$\\n\$\\nBefore deinstallation BaseCamp must be closed for allowing deletion of the map data.\$\\n\$\\nChoose Next for starting the deinstallation.\"\n" );
  printf { $fh } ( "LangString UIWpText \${LANG_GERMAN} \"Dieser Assistent wird Sie durch die Deistallation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor dem Entfernen muss das Programm BaseCamp geschlossen werden damit Kartendateien geloescht werden koennen.\$\\n\$\\nKlicken Sie auf Weiter um mit der Deinstallation zu beginnen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString UIFpTitle \${LANG_ENGLISH} \"Deinstallation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} finished\"\n" );
  printf { $fh } ( "LangString UIFpTitle \${LANG_GERMAN} \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh } ( "LangString UIFpText \${LANG_ENGLISH} \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} has been succesfully deinstalled from your computer.\$\\n\$\\nChoose Finish to terminate the deinstallation.\"\n" );
  printf { $fh } ( "LangString UIFpText \${LANG_GERMAN} \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich von Ihrem Computer entfernt.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Deinstallation abzuschliessen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString AlreadyInstalled \${LANG_ENGLISH} \"There is already a version of \${KARTEN_BESCHREIBUNG} installed.\$\\nThis version needs to be deinstalled first.\"\n" );
  printf { $fh } ( "LangString AlreadyInstalled \${LANG_GERMAN} \"Es ist bereits eine Version der \${KARTEN_BESCHREIBUNG} installiert.\$\\nDiese Version muss zunaechst entfernt werden.\"\n" );
  printf { $fh } ( "LangString AlreadyInstalledOldName \${LANG_ENGLISH} \"There is already a version of \${KARTEN_BESCHREIBUNG} installed.\$\\n(still using the old name \${REG_KEY_OLD})\$\\nThis version needs to be deinstalled first.\"\n" );
  printf { $fh } ( "LangString AlreadyInstalledOldName \${LANG_GERMAN} \"Es ist bereits eine Version der \${KARTEN_BESCHREIBUNG} installiert.\$\\n(noch mit altem Namen \${REG_KEY_OLD})\$\\nDiese Version muss zunaechst entfernt werden.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Initialize NSI-Variables\n" );
  printf { $fh } ( "; ------------------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Uninstall key: DisplayName - Name of the application\n" );
  printf { $fh } ( "Name \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installer-EXE\n" );
  printf { $fh } ( "OutFile \"\${INSTALLER_EXE_NAME}.exe\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installationsverzeichnis\n" );
  printf { $fh } ( "InstallDir \"\${INSTALLATIONS_VERZEICHNIS}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "Function myGUIInit\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Call the language selection dialog\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  ;!insertmacro MUI_LANGDLL_DISPLAY\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Uninstall before Installing (actual mapname)\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  ReadRegStr \$R0 HKLM \\\n" );
  printf { $fh } ( "  \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \\\n" );
  printf { $fh } ( "  \"UninstallString\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  StrCmp \$R0 \"\" noactualcard\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \"\$(AlreadyInstalled)\" IDOK uninstactualcard\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Run the Uninstaller\n" );
  printf { $fh } ( "  ; -------------------\n" );
  printf { $fh } ( "  uninstactualcard:\n" );
  printf { $fh } ( "  Exec \$R0\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  noactualcard:\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Uninstall before Installing (old mapname)\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  ReadRegStr \$R0 HKLM \\\n" );
  printf { $fh } ( "  \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY_OLD}\" \\\n" );
  printf { $fh } ( "  \"UninstallString\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  StrCmp \$R0 \"\" nooldcard\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \"\$(AlreadyInstalledOldName)\" IDOK uninstoldcard\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Run the Uninstaller\n" );
  printf { $fh } ( "  ; -------------------\n" );
  printf { $fh } ( "  uninstoldcard:\n" );
  printf { $fh } ( "  Exec \$R0\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  nooldcard:\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "FunctionEnd\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installer Section\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "Section \"MainSection\" SectionMain\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Get and create a temporary directory\n" );
  printf { $fh } ( "  ; ------------------------------------\n" );
  printf { $fh } ( "  Var /Global MyTempDir\n" );
  printf { $fh } ( "  GetTempFileName \$MyTempDir\n" );
  printf { $fh } ( "  Delete \$MyTempDir\n" );
  printf { $fh } ( "  CreateDirectory \$MyTempDir\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Files to be installed\n" );
  printf { $fh } ( "  ; ---------------------\n" );
  printf { $fh } ( "  SetOutPath \"\$MyTempDir\"\n" );
  printf { $fh } ( "  File \"\${MAPNAME}_InstallFiles.zip\"\n" );

  printf { $fh } ( "  !addplugindir \"\%s\\tools\\NSIS\\windows\\Plugins\"\n", $BASEPATH );

  printf { $fh } ( "  nsisunz::UnzipToLog \"\$MyTempDir\\\${MAPNAME}_InstallFiles.zip\" \"\$MyTempDir\"\n" );
  printf { $fh } ( "  Pop \$0\n" );
  printf { $fh } ( "  StrCmp \$0 \"success\" +2\n" );
  printf { $fh } ( "    call InstallError\n" );

  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; delete unpacked zip file again to safe space\n" );
  printf { $fh } ( "  Delete \"\$MyTempDir\\\${MAPNAME}_InstallFiles.zip\"\n" );

  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Clear Errors and continue\n" );
  printf { $fh } ( "  ClearErrors\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "  ; Create the Install Directory\n" );
  printf { $fh } ( "  CreateDirectory \"\$INSTDIR\"\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "  ; Copy TYP and other files\n" );

  printf { $fh } ( "  CopyFiles \"\$MyTempDir\\\${MAPNAME}.img\" \"\$INSTDIR\\\${MAPNAME}.img\"\n" );
  printf { $fh } ( "  Delete \"\$MyTempDir\\\${MAPNAME}.img\"\n" );

  printf { $fh } ( "  CopyFiles \"\$MyTempDir\\\${MAPNAME}_mdr.img\" \"\$INSTDIR\\\${MAPNAME}_mdr.img\"\n" );
  printf { $fh } ( "  Delete \"\$MyTempDir\\\${MAPNAME}_mdr.img\"\n" );
  
  printf { $fh } ( "  CopyFiles \"\$MyTempDir\\\${MAPNAME}.mdx\" \"\$INSTDIR\\\${MAPNAME}.mdx\"\n" );
  printf { $fh } ( "  Delete \"\$MyTempDir\\\${MAPNAME}.mdx\"\n" );
  
  for my $thistypfile ( @typfiles ) {
    printf { $fh } ( "  CopyFiles \"\$MyTempDir\\\%s\" \"\$INSTDIR\\\%s\"\n", $thistypfile, $thistypfile );
    printf { $fh } ( "  Delete \"\$MyTempDir\\\%s\"\n", $thistypfile );
  }
  
  printf { $fh } ( "  CopyFiles \"\$MyTempDir\\\${MAPNAME}.tdb\" \"\$INSTDIR\\\${MAPNAME}.tdb\"\n" );
  printf { $fh } ( "  Delete \"\$MyTempDir\\\${MAPNAME}.tdb\"\n" );
  
  printf { $fh } ( "\n" );

  printf { $fh } ( "  ; Copy the tiles\n" );
  for my $imgfile ( @imgfiles ) {
    printf { $fh } ( "  CopyFiles \"\$MyTempDir\\%s\" \"\$INSTDIR\\%s\"\n", $imgfile, $imgfile );
    printf { $fh } ( "  Delete \"\$MyTempDir\\%s\"\n", $imgfile );
  }

  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Check for errors\n" );
  printf { $fh } ( "  IfErrors 0 +2\n" );
  printf { $fh } ( "    Call InstallError\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "  ; Delete temporary directory and content\n" );
  printf { $fh } ( "  ; --------------------------------------\n" );
  printf { $fh } ( "  RMDir /r \$MyTempDir\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Create BaseCamp / MapSource registry keys\n" );
  printf { $fh } ( "  ; -----------------------------------------\n" );
  # e.g. dec '5819' = hex '16bb'; high = '16'; low = 'bb'
  my $hexID = sprintf ( "%04x", $familyID );
  my $hexLow  = substr ( $hexID, 2, 2 );
  my $hexHigh = substr ( $hexID, 0, 2 );
  printf { $fh } ( "  WriteRegBin HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"ID\" %s%s\n", $hexLow, $hexHigh );
  printf { $fh } ( "\n" );
  printf { $fh }
    ( "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"IDX\" \"\$INSTDIR\\\${MAPNAME}.mdx\"\n" );
  printf { $fh }
    ( "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"MDR\" \"\$INSTDIR\\\${MAPNAME}_mdr.img\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh }
    ( "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"TYP\" \"\$INSTDIR\\\${TYPNAME}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh }
    (
    "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"BMAP\" \"\$INSTDIR\\\${MAPNAME}.img\"\n"
    );
  printf { $fh }
    ( "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"LOC\" \"\$INSTDIR\"\n" );
  printf { $fh }
    (
    "  WriteRegStr HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"TDB\" \"\$INSTDIR\\\${MAPNAME}.tdb\"\n"
    );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Write uninstaller\n" );
  printf { $fh } ( "  ; -----------------\n" );
  printf { $fh } ( "  WriteUninstaller \"\$INSTDIR\\Uninstall.exe\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Create uninstaller registry keys\n" );
  printf { $fh } ( "  ; --------------------------------\n" );
  printf { $fh }
    (
    "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"DisplayName\" \"\$(^Name)\"\n" );
  printf { $fh }
    (
    "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"UninstallString\" \"\$INSTDIR\\Uninstall.exe\"\n"
    );
  printf { $fh }
    ( "  WriteRegDWORD HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"NoModify\" 1\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "SectionEnd\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Uninstaller Section\n" );
  printf { $fh } ( "; -------------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "Section \"Uninstall\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Files to be uninstalled\n" );
  printf { $fh } ( "  ; -----------------------\n" );
  printf { $fh } ( "  Delete \"\$INSTDIR\\\${MAPNAME}.img\"\n" );
  printf { $fh } ( "  Delete \"\$INSTDIR\\\${MAPNAME}_mdr.img\"\n" );
  printf { $fh } ( "  Delete \"\$INSTDIR\\\${MAPNAME}.mdx\"\n" );
#  printf { $fh } ( "  Delete \"\$INSTDIR\\\${TYPNAME}\"\n" );
  for my $thistypfile ( @typfiles ) {
    printf { $fh } ( "  Delete \"\$INSTDIR\\\%s\"\n", $thistypfile );
  }
  printf { $fh } ( "  Delete \"\$INSTDIR\\\${MAPNAME}.tdb\"\n" );

  for my $imgfile ( @imgfiles ) {
    printf { $fh } ( "  Delete \"\$INSTDIR\\%s\"\n", $imgfile );
  }
  printf { $fh } ( "  Delete \"\$INSTDIR\\Uninstall.exe\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  RmDir \"\$INSTDIR\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Registry cleanup\n" );
  printf { $fh } ( "  ; ----------------\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"ID\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"IDX\"\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"MDR\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\" \"TYP\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"BMAP\"\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"LOC\"\n" );
  printf { $fh } ( "  DeleteRegValue HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\" \"TDB\"\n" );
  printf { $fh } ( "  DeleteRegKey /IfEmpty HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\\\${PRODUCT_ID}\"\n" );
  printf { $fh } ( "  DeleteRegKey /IfEmpty HKLM \"SOFTWARE\\Garmin\\MapSource\\Families\\\${REG_KEY}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  DeleteRegKey HKLM \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "SectionEnd\n" );

  printf { $fh } ( "\n\n" );
  printf { $fh } ( "Function InstallError\n" );
  printf { $fh } ( "  DetailPrint \"\$0\"\n" );
  printf { $fh } ( "  RMDir /r \$MyTempDir\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "FunctionEnd\n" );

  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  return;
}


# -----------------------------------------
# Compile the NSI file into the final Installer for Windows
# (old style Installer containing ImageDir files)
# Tool : makensis.exe
# OS   : Linux, Windows
# -----------------------------------------
sub create_nsis_exe_full {

  my $source      = $EMPTY;
  my $destination = $EMPTY;
  my $zipper      = $EMPTY;

  # Prep for creating the Installer: get OS dependent command name for zipper
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    die ( "\nError: Function on OS X not possible.\n" );
    return ( 1 );
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $zipper = $BASEPATH . '/tools/zip/windows/7-Zip/7za.exe a ';
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $zipper = 'zip -r ';
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }

  # jump to work directory
  chdir "$WORKDIRLANG";

  # Create the needed zip file
  $source      = "$mapid*.img $mapname*.img *.tdb *.mdx *.TYP";
  $destination = $mapname . '_InstallFiles.zip';
  $command     = $zipper . "$destination $source";
  process_command ( $command );

  # Prep for creating the Installer: get OS dependent command name for nsis and zipper
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    die ( "\nError: Function on OS X not possible.\n" );
    return ( 1 );
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/NSIS/windows/makensis.exe $mapname" . ".nsi";
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $command = "makensis $mapname" . ".nsi";
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }

  # go to nsis directory
  chdir "$BASEPATH/nsis";
  
  # Create the needed license files
  create_licensefile_nsis();

  # copy needed bitmaps
  copy ( "Install.bmp",   "$WORKDIRLANG/Install.bmp" )   or die ( "copy() failed: $!" );
  copy ( "Deinstall.bmp", "$WORKDIRLANG/Deinstall.bmp" ) or die ( "copy() failed: $!" );

  # go back to work directory
  chdir "$WORKDIRLANG";

  # Run the actual NSIS compiler
  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Compilation of Windowsinstaller for $mapname failed.\n\n" );
  }

  # Put the Installer Name together
  my $filename = "Install_" . $mapname . "_" . $maplang . ".exe";

  # sleep needed on windows... perl is faster than windows... (Viruschecking ? FortiClient AppDetection)
  if ( $OSNAME eq 'MSWin32' ) {
    # Windows
    printf { *STDOUT } ( "   (...sleeping a while for preventing viruschecking to lock files...)\n" );
#    sleep 60;
    sleep 5;
  }
  
  # Try to move the Installer into the install directory
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!: move $filename $INSTALLDIR/$filename\n" );

  # Delete the zip file again, not needed anymore
  unlink ( $mapname . "_InstallFiles.zip" );

  return;

}


# -----------------------------------------
# Create the NSI file needed for compiling the Windows Installer
# (old style installer including ImageDir Set)
# -----------------------------------------
sub create_nsis_nsi_gmap {

  # Jump into the correct directory
  chdir "$WORKDIRLANG";

  printf { *STDOUT } ( "Ausgabe %s\n", $releasestring );

  # Create output
  my $filename = $mapname . "-gmap.nsi";
  printf { *STDOUT } ( "\nCreating $filename ...\n" );

  # open ( my $fh, '+>:encoding(UTF-8)', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
  open ( my $fh, '+>', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );

  # Print header Information
  printf { $fh } ( "; ------------------------------------------------------------\n" );
  printf { $fh } ( "; Script  : %s.nsi\n", $filename );
  printf { $fh } ( "; Version : $VERSION\n" );
  printf { $fh } ( "; Created : %s\n", scalar ( localtime () ) );
  printf { $fh } ( ";\n" );
  printf { $fh } ( "; Remarks:\n" );
  printf { $fh } ( "; - Separate installer for gmap zip files\n" );
  printf { $fh } ( "; - Just unzippes gmap zip file (in same directory as installer)\n" );
  printf { $fh } ( ";   into the correct location for BaseCamp\n" );
  printf { $fh } ( "; ------------------------------------------------------------\n" );
  printf { $fh } ( "\n" );
  
  # Settings and definitions
  printf { $fh } ( "; General Settings\n" );
  printf { $fh } ( "; ----------------\n" );
  printf { $fh } ( "; Map Description\n" );
  printf { $fh } ( "!define KARTEN_BESCHREIBUNG \"%s\"\n", $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Release\n" );
  printf { $fh } ( "!define KARTEN_AUSGABE \"(Ausgabe %s)\"\n", $releasestring );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name of the executable installer\n" );
  printf { $fh } ( "!define INSTALLER_EXE_NAME \"GMAP_Installer_%s_%s\"\n", $mapname, $maplang );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name of the map\n" );
  printf { $fh } ( "!define MAPNAME \"%s\"\n",     $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name of the Windows Registry\n" );
  printf { $fh } ( "!define REG_KEY \"%s\"\n",     $mapname );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Name of the GMAP Archive\n" );
  printf { $fh } ( "!define GMAP_ARCHIVE \"%s_%s.gmap.zip\"\n",     $mapname, $maplang );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Compressor Settings\n" );
  printf { $fh } ( "; -------------------\n" );
  printf { $fh } ( "SetCompress off\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Include Modern UI\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!include \"MUI2.nsh\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Other Includes\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!include \"WinVer.nsh\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Interface Settings\n" );
  printf { $fh } ( "; ------------------\n" );
  printf { $fh } ( "!define MUI_LANGDLL_ALLLANGUAGES\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "; Installer Pages\n" );
  printf { $fh } ( "; ---------------\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"\$(INWpTitle)\"\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TEXT \"\$(INWpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"\$(INFpTitle)\"\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TEXT \"\$(INFpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_WELCOMEFINISHPAGE_BITMAP Install.bmp\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_WELCOME\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_LICENSE \$(licenseFile)\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_DIRECTORY\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_INSTFILES\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_FINISH\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "; Init Routine\n" );
  printf { $fh } ( "; ------------\n" );
  printf { $fh } ( "!define MUI_CUSTOMFUNCTION_GUIINIT myGuiInit\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "; Uninstaller Pages\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"\$(UIWpTitle)\"\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TEXT \"\$(UIWpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"\$(UIFpTitle)\"\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TEXT \"\$(UIFpText)\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_UNWELCOMEFINISHPAGE_BITMAP Deinstall.bmp\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_WELCOME\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_CONFIRM\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_INSTFILES\n" );
  printf { $fh } ( "!insertmacro MUI_UNPAGE_FINISH\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  # Language Settings and String Definitions
  printf { $fh } ( "; Language Settings\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "!insertmacro MUI_LANGUAGE \"English\"\n" );
  printf { $fh } ( "!insertmacro MUI_LANGUAGE \"German\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString INWpTitle \${LANG_ENGLISH} \"Installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString INWpTitle \${LANG_GERMAN} \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString INWpText \${LANG_ENGLISH} \"This Wizard will be guiding you through the installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}.\$\\n\$\\nBefore installation BaseCamp must be closed for allowing installation of the map data.\$\\n\$\\nMake sure you have the correct GMAP zip file downloaded to the same directory as this installer.\$\\n\$\\nChoose Next for starting the installation.\"\n" );
  printf { $fh } ( "LangString INWpText \${LANG_GERMAN} \"Dieser Assistent wird Sie durch die Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor der Installation muss das Programm BaseCamp geschlossen werden damit Kartendateien ersetzt werden koennen.\$\\n\$\\nBitte stellen Sie sicher, dass die korrekte GMAP ZIP Datei schon in das gleiche Verzeichnis heruntergeladen wurde, wie dieser Installer.\$\\n\$\\nKlicken Sie auf Weiter um mit der Installation zu beginnen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LicenseLangString licenseFile \${LANG_ENGLISH} \"%s\"\n", "$mapname.nsis.license.en" );
  printf { $fh } ( "LicenseLangString licenseFile \${LANG_GERMAN} \"%s\"\n", "$mapname.nsis.license.de" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString INFpTitle \${LANG_ENGLISH} \"Installation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} finished\"\n" );
  printf { $fh } ( "LangString INFpTitle \${LANG_GERMAN} \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh } ( "LangString INFpText \${LANG_ENGLISH} \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} has been succesfully installed on your computer.\$\\n\$\\nHave fun using the map.\$\\n\$\\nFor ensuring and increasing the quality of the map also your feedback is helpful (e.g. defects or improvements). Already now many thanks for it.\$\\n\$\\nChoose Finish to terminate the installation.\"\n" );
  printf { $fh } ( "LangString INFpText \${LANG_GERMAN} \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich auf Ihrem Computer installiert.\$\\n\$\\nViel Erfolg und Freude bei der Nutzung der Karte.\$\\n\$\\nUm die Qualitaet dieser Karte zu sichern und zu verbessern ist auch Ihr Feedback (z.B. zu Defekten oder Verbesserungen) hilfreich. An dieser Stelle schon einmal Danke hierfuer.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Installation abzuschliessen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString UIWpTitle \${LANG_ENGLISH} \"Deinstalling \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString UIWpTitle \${LANG_GERMAN} \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "LangString UIWpText \${LANG_ENGLISH} \"This Wizard will be guiding you through the deinstallation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}.\$\\n\$\\nBefore deinstallation BaseCamp must be closed for allowing deletion of the map data.\$\\n\$\\nChoose Next for starting the deinstallation.\"\n" );
  printf { $fh } ( "LangString UIWpText \${LANG_GERMAN} \"Dieser Assistent wird Sie durch die Deistallation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor dem Entfernen muss das Programm BaseCamp geschlossen werden damit Kartendateien geloescht werden koennen.\$\\n\$\\nKlicken Sie auf Weiter um mit der Deinstallation zu beginnen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString UIFpTitle \${LANG_ENGLISH} \"Deinstallation of \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} finished\"\n" );
  printf { $fh } ( "LangString UIFpTitle \${LANG_GERMAN} \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh } ( "LangString UIFpText \${LANG_ENGLISH} \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} has been succesfully deinstalled from your computer.\$\\n\$\\nChoose Finish to terminate the deinstallation.\"\n" );
  printf { $fh } ( "LangString UIFpText \${LANG_GERMAN} \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich von Ihrem Computer entfernt.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Deinstallation abzuschliessen.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString AlreadyInstalled \${LANG_ENGLISH} \"There is already a version of \${KARTEN_BESCHREIBUNG} installed.\$\\nThis version will be automatically deinstalled first.\"\n" );
  printf { $fh } ( "LangString AlreadyInstalled \${LANG_GERMAN} \"Es ist bereits eine Version der \${KARTEN_BESCHREIBUNG} installiert.\$\\nDiese Version wird automatisch entfernt werden.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString MsgBoxMissingGmapZip \${LANG_ENGLISH} \"Can't find the needed ZIP file containing the gmap version of the map:\$\\n    \$EXEDIR\\\${GMAP_ARCHIVE}\$\\n\$\\nPlease download it and save it to above location.\"\n" );
  printf { $fh } ( "LangString MsgBoxMissingGmapZip \${LANG_GERMAN} \"Zip Datei mit GMAP Version der Karte fehlt:\$\\n    \$EXEDIR\\\${GMAP_ARCHIVE}\$\\n\$\\nBitte laden Sie sie herunter und speichern sie an die oben angegebene Stelle.\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString ActionUnzippingGMAP \${LANG_ENGLISH} \"Unzipping GMAP Zip File with external 7za.exe ... please wait\"\n" );
  printf { $fh } ( "LangString ActionUnzippingGMAP \${LANG_GERMAN} \"Entpacken der GMAP Zip Datei with external 7za.exe ... please wait\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "LangString UnzipGmapError \${LANG_ENGLISH} \"There was a problem uncompressing the GMAP Zip file:\"\n" );
  printf { $fh } ( "LangString UnzipGmapError \${LANG_GERMAN} \"Fehler beim entpacken der GMAP Zip Datei:\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  printf { $fh } ( "; Initialize NSI-Variables\n" );
  printf { $fh } ( "; ------------------------\n" );
  printf { $fh } ( "; Uninstall key: DisplayName - Name of the application\n" );
  printf { $fh } ( "Name \"\${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "; Installer-EXE\n" );
  printf { $fh } ( "OutFile \"\${INSTALLER_EXE_NAME}.exe\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  # Function .onInit
  printf { $fh } ( "; Function .onInit: needed for getting ProgramData dir early enough\n" );
  printf { $fh } ( "; -------------------------------------------------------------------\n" );
  printf { $fh } ( "Function .onInit\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Initiate the logging\n" );
  printf { $fh } ( "  ; ---------------------------------------------------------\n" );
  printf { $fh } ( "  !addplugindir \"\%s\\tools\\NSIS\\windows\\Plugins\"\n", $BASEPATH );
  printf { $fh } ( "  LogEx::Init true \"\$EXEDIR\\\${MAPNAME}-install.log\"\n" );
  printf { $fh } ( "  LogEx::Write  \"Init: Starting installation: \${MAPNAME} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Put the Common App Data Directory as installation default\n" );
  printf { $fh } ( "  ; ---------------------------------------------------------\n" );
  printf { $fh } ( "  SetShellVarContext all\n" );
  printf { $fh } ( "  StrCpy \$InstDir \"\$APPDATA\\Garmin\\Maps\"\n" );
  printf { $fh } ( "  LogEx::Write  \"Init: Default Installation Directory: \$InstDir\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "FunctionEnd\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  # Function myGUIINIT
  printf { $fh } ( "; Function myGUIInit: Check requirements and uninstall if needed\n" );
  printf { $fh } ( "; -------------------------------------------------------------------\n" );
  printf { $fh } ( "Function myGUIInit\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  ; Call the language selection dialog\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  ;!insertmacro MUI_LANGDLL_DISPLAY\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Check if the needed ZIP file containing GMAP exists\n" );
  printf { $fh } ( "  ; ---------------------------------------------------\n" );
  printf { $fh } ( "  IfFileExists \"\$EXEDIR\\\${GMAP_ARCHIVE}\" gmapzipexists\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Missing Gmap Archive\n" );
  printf { $fh } ( "  LogEx::Write  \"myGUIInit: Missing ZIP file: \$EXEDIR\\\${GMAP_ARCHIVE}\"\n" );
  printf { $fh } ( "  MessageBox MB_OK|MB_ICONEXCLAMATION \"\$\(MsgBoxMissingGmapZip)\"\n" );
  printf { $fh } ( "  abort\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; GMAP Archive exists - continue\n" );
  printf { $fh } ( "  gmapzipexists:\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Get the Common App Data Directory\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  Var /Global GarminMapsDir\n" );
  printf { $fh } ( "  SetShellVarContext all\n" );
  printf { $fh } ( "  StrCpy \$GarminMapsDir \"\$APPDATA\\Garmin\\Maps\"\n" );
  printf { $fh } ( "  LogEx::Write  \"myGUIInit: GarminMapsDir: \$GarminMapsDir\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Check if we already have the same map installed via NSIS\n" );
  printf { $fh } ( "  ; --------------------------------------------------------\n" );
  printf { $fh } ( "  ReadRegStr \$R0 HKLM \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"UninstallString\"\n" );
  printf { $fh } ( "  ReadRegStr \$R1 HKLM \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"InstallLocation\"\n" );
  printf { $fh } ( "  StrCmp \$R0 \"\" noactualmap\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Yes, map installed: aks user to deinstall\n" );
  printf { $fh } ( "  LogEx::Write  \"myGUIInit: Map already installed via NSIS: prompting user...\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   prompting user...\"\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \"NSIS: \$(AlreadyInstalled)\" IDOK uninstactualmap\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Run the Uninstaller and goto the installation (no further checks about dir and shortcut)\n" );
  printf { $fh } ( "  uninstactualmap:\n" );
  printf { $fh } ( "  LogEx::Write  \"   Uninstalling old installation...\"\n" );
  printf { $fh } ( "  StrLen \$R2 \${REG_KEY}\n" );  
  printf { $fh } ( "  IntOp \$R2 \$R2 + 5\n" );
  printf { $fh } ( "  StrCpy \$R3 \$R1 -\$R2\n" );
  printf { $fh } ( "  ExecWait '\"\$R0\" /S _?=\$R3'\n" );
  printf { $fh } ( "  Delete \"\$R0\"\n" );
  printf { $fh } ( "  BringToFront\n" );
  printf { $fh } ( "  goto finished\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Same Map not installed via NSIS, lets continue\n" );
  printf { $fh } ( "  noactualmap:\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Check if the map to be installed already exists: Directory\n" );
  printf { $fh } ( "  ; ----------------------------------------------------------\n" );
  printf { $fh } ( "  IfFileExists \"\$GarminMapsDir\\\${MAPNAME}.gmap\\*.*\" askfordirdeletion\n" );
  printf { $fh } ( "  goto nogmapdirinstalled\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ;the GMAP directory for this map exists already: ask user\n" );
  printf { $fh } ( "  askfordirdeletion:\n" );
  printf { $fh } ( "  LogEx::Write  \"myGUIInit: GMAP Directory already exists: \${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   prompting user...\"\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \"Directory: \$(AlreadyInstalled)\" IDOK deletegmapdir\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; If needed and wished: remove old existing gmap directory\n" );
  printf { $fh } ( "  deletegmapdir:\n" );
  printf { $fh } ( "  LogEx::Write  \"   Removing existing GMAP Directory ...\"\n" );
  printf { $fh } ( "  RMDir /r \"\$GarminMapsDir\\\${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; no existing GMAP directory for this map, lets continue\n" );
  printf { $fh } ( "  nogmapdirinstalled:\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Check if there is a shortcut in the GarminMapsDir for this map\n" );
  printf { $fh } ( "  ; --------------------------------------------------------------\n" );
  printf { $fh } ( "  IfFileExists \"\$GarminMapsDir\\\${MAPNAME}.gmap.lnk\" askforlinkdeletion\n" );
  printf { $fh } ( "  goto nogmaplinkinstalled\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; There is a shortcut for this map: ask user\n" );
  printf { $fh } ( "  askforlinkdeletion:\n" );
  printf { $fh } ( "  LogEx::Write  \"myGUIInit: GMAP Directory Shortcut exists: \${MAPNAME}.gmap.lnk\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   prompting user...\"\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \"ShortCut: \$(AlreadyInstalled)\" IDOK deletegmaplink\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; If needed and wished: remove old existing gmap shortcut\n" );
  printf { $fh } ( "  deletegmaplink:\n" );
  printf { $fh } ( "  LogEx::Write  \"   Removing GMAP Directory Shortcut ...\"\n" );
  printf { $fh } ( "  Delete \"\$GarminMapsDir\\\${MAPNAME}.gmap.lnk\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; All fine, lets continue\n" );
  printf { $fh } ( "  nogmaplinkinstalled:\n" );
  printf { $fh } ( "  finished:\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "FunctionEnd\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  # Installer Section
  printf { $fh } ( "; Installer Section\n" );
  printf { $fh } ( "; -----------------\n" );
  printf { $fh } ( "Section \"MainSection\" SectionMain\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Get and create a temporary directory\n" );
  printf { $fh } ( "  ; ------------------------------------\n" );
  printf { $fh } ( "  Var /Global MyTempDir\n" );
  printf { $fh } ( "  GetTempFileName \$MyTempDir\n" );
  printf { $fh } ( "  Delete \$MyTempDir\n" );
  printf { $fh } ( "  CreateDirectory \$MyTempDir\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Created Temp Dir: \$MyTempDir\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Log some stuff\n" );
  printf { $fh } ( "  ; ---------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Installation Directory: \$INSTDIR\"\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Garmin Maps Directory:  \$GarminMapsDir\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Get System Information:\n" );
  printf { $fh } ( "  ; ---------------------\n" );
  printf { $fh } ( "  \${WinVerGetMajor} \$R0\n" );
  printf { $fh } ( "  \${WinVerGetMinor} \$R1\n" );
  printf { $fh } ( "  \${WinVerGetBuild} \$R2\n" );
  printf { $fh } ( "  \${WinVerGetServicePackLevel} \$R3\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Windows Build:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   Kernel \$R0.\$R1 build \$R2\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   SP \$R3\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Print Garmin Maps Dir content:\n" );
  printf { $fh } ( "  ; ------------------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"   pre installation:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Garmin Maps Dir:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   --------------------------------------------------------------------------------\"\n" );
  printf { $fh } ( "  ExecDos::exec 'cmd /C dir \$GarminMapsDir' \"\" \"\$MyTempDir\\garminmapsdir-output.log\"\n" );
  printf { $fh } ( "  LogEx::AddFile \"   \" \"\$MyTempDir\\garminmapsdir-output.log\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   --------------------------------------------------------------------------------\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Extract 7za.exe\n" );
  printf { $fh } ( "  ; ---------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Extracting 7za.exe:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   dst: \$MyTempDir\"\n" );
  printf { $fh } ( "  SetOutPath \"\$MyTempDir\"\n" );
  printf { $fh } ( "  File \"\%s\\tools\\zip\\windows\\7-Zip\\7za.exe\"\n", $BASEPATH );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Execute 7za.exe to unzip GMAP Archive to choosen directory\n" );
  printf { $fh } ( "  ; ----------------------------------------------------------\n" );
  printf { $fh } ( "  DetailPrint \"\$(ActionUnzippingGMAP)\"\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Extracting zip file\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   src: \$EXEDIR\\\${GMAP_ARCHIVE}\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   dst: \$INSTDIR\"\n" );
  printf { $fh } ( "  ExecWait '\"\$MyTempDir\\7za.exe\" x \"\$EXEDIR\\\${GMAP_ARCHIVE}\" -aoa -o\"\$INSTDIR\"' \$0\n" );
  printf { $fh } ( "  Pop \$0\n" );
  printf { $fh } ( "  IntCmp \$0 0 +2\n" );
  printf { $fh } ( "  call InstallError\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Clear Errors and continue\n" );
  printf { $fh } ( "  ClearErrors\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Create the sortcut if needed (INSTDIR <> GarminMapsDir)\n" );
  printf { $fh } ( "  ; -------------------------------------------------------\n" );
  printf { $fh } ( "  StrCmp \$INSTDIR \$GarminMapsDir noShortcutNeeded\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Shortcut needed\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Shortcut needed\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   just in case: create: \$GarminMapsDir\"\n" );
  printf { $fh } ( "  CreateDirectory \$GarminMapsDir\n" );
  printf { $fh } ( "  LogEx::Write  \"   create Shortcut:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"      src: \$GarminMapsDir\\\${MAPNAME}.gmap.lnk\"\n" );
  printf { $fh } ( "  LogEx::Write  \"      dst: \$INSTDIR\\\${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  CreateShortCut \"\$GarminMapsDir\\\${MAPNAME}.gmap.lnk\" \"\$INSTDIR\\\${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Check for errors\n" );
  printf { $fh } ( "  IfErrors 0 +2\n" );
  printf { $fh } ( "  Call InstallError\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; No Shortcut needed, let's continue\n" );
  printf { $fh } ( "  noShortcutNeeded:\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Print Garmin Maps Dir content:\n" );
  printf { $fh } ( "  ; ------------------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"   pre installation:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Garmin Maps Dir:\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   --------------------------------------------------------------------------------\"\n" );
  printf { $fh } ( "  ExecDos::exec 'cmd /C dir \$GarminMapsDir' \"\" \"\$MyTempDir\\garminmapsdir-output.log\"\n" );
  printf { $fh } ( "  LogEx::AddFile \"   \" \"\$MyTempDir\\garminmapsdir-output.log\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   --------------------------------------------------------------------------------\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Delete temporary directory and content\n" );
  printf { $fh } ( "  ; --------------------------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: remove Temp Dir again ...\"\n" );
  printf { $fh } ( "  RMDir /r \$MyTempDir\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Write Uninstaller\n" );
  printf { $fh } ( "  ; -----------------\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: write Uninstaller\"\n" );
  printf { $fh } ( "  LogEx::Write  \"   dst: \$INSTDIR\\\${MAPNAME}-Uninstall.exe\"\n" );
  printf { $fh } ( "  WriteUninstaller \"\$INSTDIR\\\${MAPNAME}-Uninstall.exe\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Create Uninstaller registry keys\n" );
  printf { $fh } ( "  ; --------------------------------\n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Write Registry ...\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"DisplayName\" \"\$(^Name)\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"UninstallString\" \"\$INSTDIR\\\${MAPNAME}-Uninstall.exe\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"InstallLocation\" \"\$INSTDIR\\\${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"Publisher\" \"Freizeitkarte OSM\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"URLInfoAbout\" \"http://www.freizeitkarte-osm.de\"\n" );
  printf { $fh } ( "  WriteRegStr HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"DisplayVersion\" \"\${KARTEN_AUSGABE}\"\n" );
  printf { $fh } ( "  WriteRegDWORD HKLM \"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \"NoModify\" 1\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  LogEx::Write  \"SectionMain: Finished Installation\"\n" );
  printf { $fh } ( "  LogEx::Close\n" );

  printf { $fh } ( "SectionEnd\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "\n" );

  # Uninstaller Section
  printf { $fh } ( "; Uninstaller Section\n" );
  printf { $fh } ( "; -------------------\n" );
  printf { $fh } ( "Section \"Uninstall\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Remove existing GMAP directory\n" );
  printf { $fh } ( "  RMDir /r \"\$INSTDIR\\\${MAPNAME}.gmap\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Get the Common App Data Directory\n" );
  printf { $fh } ( "  SetShellVarContext all\n" );
  printf { $fh } ( "  StrCpy \$GarminMapsDir \"\$APPDATA\\Garmin\\Maps\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Do we need to delete a shortcut ? (INSTDIR <> GarminMapsDir)\n" );
  printf { $fh } ( "  StrCmp \$INSTDIR \$GarminMapsDir +2\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Delete the shortcut\n" );
  printf { $fh } ( "  Delete \"\$GarminMapsDir\\\${MAPNAME}.gmap.lnk\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Registry cleanup\n" );
  printf { $fh } ( "  DeleteRegKey HKLM \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "  ; Delete the Installer itself\n" );
  printf { $fh } ( "  Delete \"\$INSTDIR\\\${MAPNAME}-Uninstall.exe\"\n" );
  printf { $fh } ( "  \n" );
  printf { $fh } ( "SectionEnd\n" );
  printf { $fh } ( "\n" );

  # Function InstallError
  printf { $fh } ( "; Function InstallError\n" );
  printf { $fh } ( "; ---------------------\n" );
  printf { $fh } ( "Function InstallError\n" );
  printf { $fh } ( "  LogEx::Write  \"InstallError: \$0\"\n" );
  printf { $fh } ( "  DetailPrint \"\$0\"\n" );
  printf { $fh } ( "  RMDir /r \$MyTempDir\n" );
  printf { $fh } ( "  DetailPrint \" \"\n" );
  printf { $fh } ( "  DetailPrint \"\$(UnzipGmapError)\"\n" );
  printf { $fh } ( "  DetailPrint \"\$EXEDIR\\\${GMAP_ARCHIVE}\"\n" );
  printf { $fh } ( "  LogEx::Write  \"InstallError: Aborting...\"\n" );
  printf { $fh } ( "  LogEx::Close\n" );
  printf { $fh } ( "  Abort\n" );
  printf { $fh } ( "FunctionEnd\n" );

  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  return;
}


# -----------------------------------------
# Compile the NSI file into the final Installer for Windows
# (old style Installer containing ImageDir files)
# Tool : makensis.exe
# OS   : Linux, Windows
# -----------------------------------------
sub create_nsis_exe_gmap {

  my $source      = $EMPTY;
  my $destination = $EMPTY;
  my $zipper      = $EMPTY;

  # Prep for creating the Installer: get OS dependent command name for nsis and zipper
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    die ( "\nError: Function on OS X not possible.\n" );
    return ( 1 );
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/NSIS/windows/makensis.exe $mapname" . "-gmap.nsi";
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $command = "makensis $mapname" . "-gmap.nsi";
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }

  # go to nsis directory
  chdir "$BASEPATH/nsis";

  # Create the needed license files
  create_licensefile_nsis();

  # copy needed bitmaps
  copy ( "Install.bmp",   "$WORKDIRLANG/Install.bmp" )   or die ( "copy() failed: $!" );
  copy ( "Deinstall.bmp", "$WORKDIRLANG/Deinstall.bmp" ) or die ( "copy() failed: $!" );

  # go back to work directory
  chdir "$WORKDIRLANG";

  # Run the actual NSIS compiler
  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Compilation of Windowsinstaller for $mapname failed.\n\n" );
  }

  # Put the Installer Name together
  my $filename = "GMAP_Installer_" . $mapname . "_" . $maplang . ".exe";

  # sleep needed on windows... perl is faster than windows... (Viruschecking ? FortiClient AppDetection)
  if ( $OSNAME eq 'MSWin32' ) {
    # Windows
    printf { *STDOUT } ( "   (...sleeping a while for preventing viruschecking to lock files...)\n" );
#    sleep 60;
    sleep 5;
  }
  
  # Try to move the Installer into the install directory
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!: move $filename $INSTALLDIR/$filename\n" );

  return;

}


# -----------------------------------------
# Create the GMAP Format of the file (Basecamp)
# - Tool : jmc_cli
# - OS   : Linux, OS X, Windows
# - Version: 0.7
#
# Usage:
# jmc_cli source_folder
# 
# or
# 
# jmc_cli -src=source_folder [-dest=destination_folder] [-bmap=basemap.img] [-gmap=mapname.gmap] [-v]
# 
# or
# 
# jmc_cli -config=mapname.cfg [-v]
# 
# Parameters:
# -src     (Relative) path to folder with map files you want to convert
# -dest    (Relative) path to folder where the .gmap folder will be created
#          (optional; when omitted the parent folder of source_folder will be used)
# -bmap    Name of .img file with overview map (optional)
#          (Needed only when jmc_cli cannot decide which file to use)
# -gmap    Name of .gmap folder (optional; when omitted the map name will be used)
# -v       Verbose output: display every step in the process (optional)
# -config  Use parameters from config file; see sample
# 
# Use quotes around paths when they contain spaces, or (Mac/Linux only) escape
# the spaces with backslashes (not in the config file!).
# 
# Status codes:
# 
# 0: success
# 1: wrong parameters
# 2: missing files
# 3: error in processing files
# 4: unhandled exception
# -----------------------------------------
sub create_gmapfile_jmc_cli {

  # jump to correct directory
  chdir "$WORKDIRLANG";

  # rmove eventually existing directories from the install directory
  rmtree ( "$INSTALLDIR/$mapname.gmap", 0, 1 );

  # Create the config file we use for jmc_cli (v0.7)1
  my $filename = "$WORKDIRLANG/jmc_cli.cfg";
  printf { *STDOUT } ( "Creating $filename ...\n" );
  open ( my $fh, '+>', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );

  printf { $fh } 
    (   "# ------------------------------------------------------------------------------\n" 
      . "# Configurationfile used for jmc_cli call\n"
      . "# Version needed: 0.7 (or higher)\n"
      . "# created : " 
      . localtime () . "\n\n"
      . "# (complete example configuration file can be found in binary directory)\n" 
      . "# ------------------------------------------------------------------------------\n" );

  printf { $fh } ( "\n# Required options:\n" );
  printf { $fh } ( "# -----------------\n" );
  
  # add requiered source and destination directory to the config file
  printf { $fh } ( "sourcefolder = $WORKDIRLANG\n" );
  printf { $fh } ( "destfolder = $INSTALLDIR\n" );
  
  printf { $fh } ( "\n# Optional stuff options:\n" );
  printf { $fh } ( "# -----------------------\n" );
  
  # add requiered source and destination directory to the config file
  printf { $fh } ( "basemap = $mapname.img\n" );
  printf { $fh } ( "TYPfile = $mapid.TYP\n" );

  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );



  # put the options for the jmc call together
  my $jmc_parameter = "-v -config=\"$WORKDIRLANG/jmc_cli.cfg\"";

  if ( $OSNAME eq 'darwin' ) {
    # OS X
    $command = "$BASEPATH/tools/jmc/osx/jmc_cli $jmc_parameter";
#    process_command ( $command );
  }	
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/jmc/windows/jmc_cli.exe $jmc_parameter";
#    process_command ( $command );
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $command = "$BASEPATH/tools/jmc/linux/jmc_cli $jmc_parameter";
#    process_command ( $command );
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }

  # call jmc
  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  creating the gmap version of the map $mapname failed.\n\n" );
  }

#  # Copy the rest of the TYP files (actually hidden in a TYP subdirectory of the WORKDIR)
#  chdir "$WORKDIR/TYP";
#  for my $file ( <*.TYP> ) {
#    printf { *STDOUT } ( "Copying %s\n", $file );
#    copy ( $file, "$INSTALLDIR/$mapname.gmap" . "/" . $file ) or die ( "copy() $file failed: $!\n" );
#  }  

  return;
}

# -----------------------------------------
# Set the common options for mkgmap
# -----------------------------------------
# used for gmapsupp and gmapfile
sub set_mkgmap_common_parameter {

  my $tmp_description = "$mapname (Release $releasestring)";
  
  # make sure the description is not more than 50 characters
  if ( length($tmp_description) > 50 ) {
     $tmp_description = "$mapname ($releasestring)";
	 if ( length($tmp_description) > 50 ) {
	 $tmp_description = substr( $tmp_description, 0, 50 );
	 }
  }

  $mkgmap_common_parameter = sprintf (
        "--index --split-name-index "
	  . "--code-page=$mapcodepage "
      . "--license-file=$mapname.license "
      . "--product-id=1 --family-id=$mapid --family-name=\"$mapname\" "
      . "--series-name=\"$mapname\" --description=\"$tmp_description\" "
      . "--overview-mapname=\"$mapname\" --overview-mapnumber=%s0000 "
      . "--product-version=\"%d\" $mapid*.img $mapid.TYP "
      . "--tdbfile "
      . "--show-profiles=1 ",
      $mapid,$releasenumeric
  );

}


# -----------------------------------------
# create gmapsupp.img: format for GPS device
# -----------------------------------------
sub create_gmapsuppfile {

  # Jump to the work directory
  chdir "$WORKDIRLANG";

  # create License file
  create_licensefile;

  # set common parameters
  set_mkgmap_common_parameter;

  # mkgmap-Parameter
  # --description: Anzeige des Kartennamens in BaseCamp
  # --description: alleinige Anzeige des Kartennamens in einigen GPS-Geräten (z.B. 62er)
  # --description: zusätzliche Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --family-name: primäre Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --series-name: This name will be displayed in MapSource in the map selection drop-down.
  my $mkgmap_parameter = sprintf (
        "--gmapsupp "
      . "$mkgmap_common_parameter"
  );
 
  # run mkgmap to create the actual gmapsupp.img
  $command =
      "java -Xmx"
    . $javaheapsize . "M"
    . " -Dfile.encoding=UTF-8 -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs $mkgmap_parameter";

  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Creation of the file gmapsupp.img for $mapname failed.\n\n" );
  }

  # copy the created gmapsupp to the install directory
  my $filename = "gmapsupp.img";
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!\n" );

  # remove the unneeded temporary files again
  unlink ( "osmmap.tdb" );
  unlink ( "osmmap.img" );

  return;
}


# -----------------------------------------
# create gmap for basecamp: using mkgmap
# -----------------------------------------
sub create_gmapfile {

  # Jump to the work directory
  chdir "$WORKDIRLANG";

  # create License file
  create_licensefile;
  
  # set common parameters
  set_mkgmap_common_parameter;

  # mkgmap-Parameter
  # --description: Anzeige des Kartennamens in BaseCamp
  # --description: alleinige Anzeige des Kartennamens in einigen GPS-Geräten (z.B. 62er)
  # --description: zusätzliche Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --family-name: primäre Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --series-name: This name will be displayed in MapSource in the map selection drop-down.
  my $mkgmap_parameter = sprintf (
        "--gmapi "
      . "$mkgmap_common_parameter"
  );

  # run mkgmap to create the actual gmap archive
  $command =
      "java -Xmx"
    . $javaheapsize . "M"
    . " -Dfile.encoding=UTF-8 -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs $mkgmap_parameter";

  process_command ( $command );

  # Check Return Value
  if ( $? != 0 ) {
      die ( "ERROR:\n  Creation of the GMAP Archive for $mapname failed.\n\n" );
  }


  # copy the created gmapsupp to the install directory
#
  my $filename = "$mapname.gmap";
  rmtree ( "$INSTALLDIR/$filename",    0, 1 );
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!\n" );
  #
  ## remove the unneeded temporary files again
  #unlink ( "osmmap.tdb" );
  #unlink ( "osmmap.img" );
  
  return;
}


# -----------------------------------------
# Create imageDir format readable by 
# - BaseCamp and Mapsource (with the needed Registry entries on Windows)
# - Qlandkarte GT
# Content:
# - *.img, *.tdb, *.mdx, *.TYP
# -----------------------------------------
sub create_image_directory {

  # Jump to the work directory
  chdir "$WORKDIRLANG";

  my $destdir = "$INSTALLDIR/$mapname" . "_Images";

  # remove eventially existing imagedir directory in the install Dir
  rmtree ( $destdir, { verbose => 1, safe => 1, keep_root => 1 } );

  # create the imageDir again
  mkpath ( $destdir, { verbose => 1 } );

  # copy all img files
  for my $file ( <*.img> ) {
    if ( $file =~ /ovm_/) {
      # overview file, skip it
    }
    else {
      printf { *STDOUT } ( "Copying %s\n", $file );
      copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
    }
  }

  # copy tdb file
  for my $file ( <*.tdb> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }

  # copy mdx file
  for my $file ( <*.mdx> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }

  # copy all TYP files
  for my $file ( <*.TYP> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }
  
  return;
}


# -----------------------------------------
# Zip the files created in the install directory
# -----------------------------------------
sub zip_maps {

  # go to the install directory
  chdir "$INSTALLDIR";

  # Initialize some variables
  my $source      = $EMPTY;
  my $source1     = $EMPTY;
  my $source2     = $EMPTY;
  my $destination = $EMPTY;
  my $zipper      = $EMPTY;

  # get the needed tool (OS depending)
  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $zipper = 'zip -r ';
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $zipper = $BASEPATH . '/tools/zip/windows/7-Zip/7za.exe a ';
  }
  else {
    die ( "\nError: Operating system $OSNAME not supported.\n" );
    return ( 1 );
  }

  # gmap (example: Freizeitkarte_DEU.gmap -> Freizeitkarte_DEU_de.gmap.zip)
  $source      = $mapname . '.gmap';
  $destination = $mapname . '_' . $maplang . '.gmap.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # old Installer (example: Install_Freizeitkarte_DEU_de.exe )
  $source      = "Install_" . $mapname . '_' . $maplang . '.exe';
  $destination = "Install_" . $mapname . '_' . $maplang . '.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # GMAP Installer (example: GMAP_Installer_Freizeitkarte_DEU_de.exe )
  $source      = "GMAP_Installer_" . $mapname . '_' . $maplang . '.exe';
  $destination = "GMAP_Installer_" . $mapname . '_' . $maplang . '.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # GMAP Full Package  (example: GMAP_Installer_Freizeitkarte_DEU_de.exe + Freizeitkarte_DEU_de.gmap.zip -> GMAP_Installer_Freizeitkarte_DEU_de_full.zip)
  $source1     = "GMAP_Installer_" . $mapname . '_' . $maplang . '.exe';
  $source2     = $mapname . '_' . $maplang . '.gmap.zip';
  $destination = "GMAP_Installer_" . $mapname . '_' . $maplang . '_full.zip';
  $command     = $zipper . "$destination $source1 $source2";
  if ( ( -e $source1 ) and ( -e $source2 ) ) {
    process_command ( $command );
  }

  # gmapsupp (example: gmapsupp.img -> DEU_de_gmapsupp.img.zip)
  $source = 'gmapsupp.img';
  $destination = $mapcode . '_' . $maplang . '_' . $source . '.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # imagedir (example: Freizeitkarte_DEU_Images -> Freizeitkarte_DEU_de.Images.zip)
  $source      = $mapname . '_Images';
  $destination = $mapname . '_' . $maplang . '.Images.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  return;
}


# -----------------------------------------
# check if a file seems to be a proper *.osm.pbf file
# - checks for existence of the string 'OSMHeader' in the file header
# - implementation is possibly unsufficiant
# -----------------------------------------
sub check_osmpbf {

  my $filename         = shift;
  my $is_osmpbf_format = 0;

  if ( -e $filename ) {
    my $datablock = '';
    open ( my $fh, '<', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );
    my $chars_read = read ( $fh, $datablock, 128 );
    if ( $chars_read == 128 ) {
      if ( $datablock =~ /OSMHeader/ ) {
        $is_osmpbf_format = 1;
      }
    }
    close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );
  }

  return ( $is_osmpbf_format );
}


# -----------------------------------------
# Extracting fzk specific regions
# out of a downloaded OSM Data extract
# -----------------------------------------
sub extract_regions {

  # If this map is a downloaded extract from which we extract further regions, continue
  if ( $maptype == 1 ) {
  
     # Initialisations
     # we don't need to cut 'joined' stuff anymore, just the OSM data
     #my $source_filename = "$WORKDIR/$mapname.osm.pbf";
     my $source_filename = "$WORKDIR/Kartendaten_$mapname.osm.pbf";
     my $osmosis_parameter = "";
     my $osmosis_parameter_bw = "";
     my $max_tee = 10;
     my @childmapnames = ();
     my $osmosis_runs = 0;
     my $actual_tee = 0;
   
     # Check if the source file exists and is a valid osm.pbf file
     if ( -e $source_filename ) {
       if ( !check_osmpbf ( $source_filename ) ) {
         die ( "\nError: Resulting data file <$source_filename> is not a valid osm.pbf file.\n" );
         return ( 1 );
       }
     }
     else {
       die ( "\nError: Source data file <$source_filename> does not exists.\n" );
       return ( 1 );
     }
   
     # add the Java-Options for the osmosis call (Environment)
     my $javacmd_options = '-Xmx' . $javaheapsize . 'M';
     $ENV{ JAVACMD_OPTIONS } = $javacmd_options;

     # Run through the mapArray and check for regions belonging to that map -> fill array childmapnames
	 for my $tmp_mapdata ( @maps ) {
	    if ( @$tmp_mapdata[ $MAPPARENT ] eq $mapcode ) {
		   push(@childmapnames, @$tmp_mapdata[ $MAPNAME ]);
		}
	 }
     
     # Check how many times we'll have to run osmosis
     $osmosis_runs = int ( ( scalar @childmapnames - 1 ) / $max_tee ) + 1;
     
     # Loop for the possibly multiple 
     for (my $i=1 ; $i <= $osmosis_runs; $i++ ) {
		        
        #Initialisation
        $osmosis_parameter_bw = "";
        my $childmapname = "";
        $actual_tee = 0;
                
        # Loop through the the childmaps until max is reached or we're finished
        for (my $j=1 ; ( $j <= $max_tee and scalar @childmapnames >= 1 ) ; $j++ ) {

           # keep the current counter
           $actual_tee = $j;
           
           # Get the actual childmapname
           $childmapname = shift(@childmapnames);
           
           # Add the needed arguments for the osmosis run for this childmap
           $osmosis_parameter_bw = $osmosis_parameter_bw
             . " --bounding-polygon file=$BASEPATH/poly/$childmapname.poly"
             . " --write-pbf file=$WORKDIR/Kartendaten_$childmapname.osm.pbf omitmetadata=yes";
		   		   
		}
		
    	# ok, enough together, let's run it (MISSING: IS IT THE LAST ?)
		printf { *STDERR } ( "\nExtracting Freizeitkarte regions ...\n" );

        # osmosis parameter
        $osmosis_parameter =
            " --read-pbf file=$source_filename"
          . " --tee $actual_tee"
          . " $osmosis_parameter_bw"
          ;

        if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
          # OS X, Linux, FreeBSD, OpenBSD
          $command = "sh $BASEPATH/tools/osmosis/bin/osmosis $osmosis_parameter";
        }
        elsif ( $OSNAME eq 'MSWin32' ) {
          # Windows
          $command = "$BASEPATH/tools/osmosis/bin/osmosis.bat $osmosis_parameter";
        }
        else {
          die ( "\nFehler: Operating System $OSNAME not supported.\n" );
          return ( 1 );
        }	
        
        # Run the acual extraction via osmosis
        process_command ( $command );

        # Check Return Value
        if ( $? != 0 ) {
           die ( "ERROR:\n  Cutting our own regions out of $mapname failed.\n\n" );
        }

     }
  }
  else {
     die ( "\nERROR: $mapname is not an extract from which we create our own regions \n" );
     return ( 1 );
  }

  return;
}


# ---------------------------------------------------------------------
# Either extract the needed OSM data from the parent Region file or,
# if already cut, just copy it
# ---------------------------------------------------------------------
sub extract_osm {
	
  # If this map is a regions that needed to be extracted, try to fetch the extracted region
  if ( $maptype == 2 ) {

     # Initialisation
     my $mapparentname = $EMPTY;
	 
	 # Get the proper Map Parent's Name
	 for my $tmp_mapdata ( @maps ) {
	    if ( @$tmp_mapdata[ $MAPCODE ] eq $mapparent ) {
		   $mapparentname = @$tmp_mapdata[ $MAPNAME ];
		   last;
		}
	 }

     # fill out source and destination variables
     my $source_filename      = "$BASEPATH/work/$mapparentname/Kartendaten_$mapname.osm.pbf";
     my $parent_filename      = "$BASEPATH/work/$mapparentname/Kartendaten_$mapparentname.osm.pbf";
     my $destination_filename = "$WORKDIR/Kartendaten_$mapname.osm.pbf";

     # Check if the source file does exist already
     if ( !(-e $source_filename ) ) {
		# NOT existing, let's try to cut it
		
		# Initialise few variables for the osmosis run
        my $osmosis_parameter = "";

         # Check if the source file exists and is a valid osm.pbf file
         if ( -e $parent_filename ) {
           if ( !check_osmpbf ( $parent_filename ) ) {
             printf { *STDERR } ( "\nError: Resulting data file <$parent_filename> is not a valid osm.pbf file.\n" );
             return ( 1 );
           }
         }
         else {
           printf { *STDERR } ( "\nError: Source data file <$parent_filename> does not exists.\n" );
           printf ( "       Did you already download the osmdata of the map $mapparentname ?\n\n" );
           return ( 1 );
         }
		 
		 # Let's put the parameters together for the osmosis run
         $osmosis_parameter =
            " --read-pbf file=$parent_filename"
          . " --tee 1"
          . " --bounding-polygon file=$BASEPATH/poly/$mapname.poly"
          . " --write-pbf file=$source_filename omitmetadata=yes";

         # Ok, let's run osmosis, depending on the OS
         printf { *STDERR } ( "\nExtracting needed data from OSM data file $source_filename ...\n" );
         if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
           # OS X, Linux, FreeBSD, OpenBSD
           $command = "sh $BASEPATH/tools/osmosis/bin/osmosis $osmosis_parameter";
         }
         elsif ( $OSNAME eq 'MSWin32' ) {
           # Windows
           $command = "$BASEPATH/tools/osmosis/bin/osmosis.bat $osmosis_parameter";
         }
         else {
           die ( "\nError: Operating System $OSNAME not supported.\n" );
         }	

        # Run the acual extraction via osmosis
        process_command ( $command );

        # Check Return Value
        if ( $? != 0 ) {
           die ( "ERROR:\n  Cutting out the data for $mapname failed.\n\n" );
        }

     }


  	 # File already exists or has just been created: let's try to copy the file
     printf { *STDERR } ( "\nCopying the existing OSM data file $source_filename ...\n" );
     copy ( "$source_filename", "$destination_filename" ) or die ( "copy($source_filename , $destination_filename) failed: $!\n" );
     printf { *STDERR } ( "\n") ;

  }  
  else {
     die ( "\nERROR: $mapname is not a region that needed local extraction.\n" );
  }

}


# -----------------------------------------------
# Get stuff already prepared in a bigger regions map directory
# -----------------------------------------------
sub fetch_mapdata {
	
  # If this map is a regions that needed to be extracted, try to fetch the extracted region
  if ( $maptype == 2 ) {

     # Initialisation
     my $mapparentname = $EMPTY;
	 
	 # Get the proper Map Parent's Name
	 for my $tmp_mapdata ( @maps ) {
	    if ( @$tmp_mapdata[ $MAPCODE ] eq $mapparent ) {
		   $mapparentname = @$tmp_mapdata[ $MAPNAME ];
		   last;
		}
	 }

     # fill out source and destination variables
     my $source_filename      = "$BASEPATH/work/$mapparentname/$mapname.osm.pbf";
     my $destination_filename = "$WORKDIR/$mapname.osm.pbf";

     # Check if the source file does exist (means that the regions have been prepared properly)
     if ( !( -e $source_filename ) ) { 
	    die ( "Can't find the source map file $source_filename !\n... looks like something is not prepared properly\n" );
     }
  
     # Source file exists, therefore fetch it
     copy ( "$source_filename", "$destination_filename" ) or die ( "copy($source_filename , $destination_filename) failed: $!\n" );
	  
  }
  else {
     die ( "\nERROR: $mapname is not a region that needed local extraction.\n" );
     return ( 1 );
  }

  return;
}


# -----------------------------------------------
# Show fingerprint: versions of tools and files
# -----------------------------------------------
sub show_fingerprint {
	
	my $versioncmd = "";
	my $cmdoutput = "";
	my $filehandle = "";
	my $lineoffile = "";
	my $inputfile = "";
	
	printf "\n\n\n";
  printf "================================================\n";
  printf "+                                              +\n";
  printf "+ Fingerprint:                                 +\n";
  printf "+ ------------                                 +\n";    
  printf "+ Show versions of used tools                  +\n";    
  printf "+                                              +\n";    
  printf "================================================\n";
  printf "\n";
  
  # General OS Information
  # ----------------------
  printf "OS General\n";
  printf "======================================\n";
  printf "Perl Version:     $PERL_VERSION\n";
  printf "Perl LC_CTYPE:    " . setlocale(LC_CTYPE) . "\n";
	printf "OS Name:          $OSNAME\n";
	printf "OS Sysname:       $os_sysname\n";
	printf "OS Nodename:      $os_nodename\n";
	printf "OS Release:       $os_release\n";
	printf "OS Version:       $os_version\n";
	printf "OS Machine:       $os_machine\n";
	printf "OS Architecture:  $os_archbit\n";
	printf "\n\n";
	

	# java
	# ----
  printf "Java\n";
  printf "======================================\n";
  chdir "$BASEPATH/tools/fzkJavaLocale";
  $cmdoutput = `java -version 2>&1`;
  printf "$cmdoutput\n\n";

  printf "Java Encodings (no parameters)\n";
  printf "--------------------------------------\n";
  chdir "$BASEPATH/tools/fzkJavaLocale";
  $cmdoutput = `java fzkJavaLocale`;
  printf "$cmdoutput\n\n";

  printf "Java Encodings (file.encoding=UTF-8)\n";
  printf "--------------------------------------\n";
  chdir "$BASEPATH/tools/fzkJavaLocale";
  $cmdoutput = `java "-Dfile.encoding=UTF-8" fzkJavaLocale`;
  printf "$cmdoutput\n\n";
  chdir "$BASEPATH";


	# osmosis
	# -------
  printf "osmosis\n";
  printf "======================================\n";
  # OS X, Linux, FreeBSD, OpenBSD
  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
     $cmdoutput = `sh $BASEPATH/tools/osmosis/bin/osmosis -v 2>&1`;
  }
  # Windows
  elsif ( $OSNAME eq 'MSWin32' ) {
     $cmdoutput = `$BASEPATH\\tools\\osmosis\\bin\\osmosis.bat -v 2>&1`;
  }
  # Try to match
  if ( $cmdoutput =~ /INFO: (.* Version .*)/ ) {
 printf "$1\n\n\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }


  # splitter
  # --------
  printf "splitter\n";
  printf "======================================\n";
  $cmdoutput = `java -jar $BASEPATH/tools/splitter/splitter.jar --version 2>&1`;
	printf "$cmdoutput\n\n";
    

  # mkgmap
  # ------
  printf "mkgmap\n";
  printf "======================================\n";    
  $cmdoutput = `java -jar $BASEPATH/tools/mkgmap/mkgmap.jar --version 2>&1`;
  # Try to match
  if ( $cmdoutput =~ /^(\d{4,})/m ) {
      printf "mkgmap r$1\n\n\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }
  


  # PPP
  # ----------------
  printf "PPP - Perl Preprocessor\n";
  printf "======================================\n";
  $cmdoutput = `perl $BASEPATH/tools/ppp/ppp.pl 2>&1`;
  # Try to match
  if ( $cmdoutput =~ /^(PERL .*)$/m ) {
      printf "$1\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }
  if ( $cmdoutput =~ /^(.*Copyright.*)$/m ) {
      printf "$1\n";
  }
  printf "\n\n";
    

  # 7za (Windows only)
  # ------------------
  printf "7-Zip CLI (7za) - Windows only\n";
  printf "======================================\n";
  # Windows
  if ( $OSNAME eq 'MSWin32' ) {
     $cmdoutput = `$BASEPATH\\tools\\zip\\windows\\7-Zip\\7za.exe 2>&1`;
     # Try to match
     if ( $cmdoutput =~ /(7-Zip .*)$/m ) {
  	  printf "$1\n";
     }
     else {
         printf "PROBLEM: either tool not found or no match for version string.\n";
         printf "         see detailed command output below:\n";
         printf "----------------------------\n";
         printf "$cmdoutput\n";
         printf "----------------------------\n\n\n";
     }
  }
  printf "\n\n";

    
  # jmc_cli
  # ------------
  printf "jmc_cli\n";
  printf "======================================\n";
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    $cmdoutput = `$BASEPATH/tools/jmc/osx/jmc_cli 2>&1`;
  }	
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $cmdoutput = `$BASEPATH\\tools\\jmc\\windows\\jmc_cli.exe 2>&1`;
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $cmdoutput = `$BASEPATH/tools/jmc/linux/jmc_cli 2>&1`;
  }
  # Try to match
  if ( $cmdoutput =~ /^(.*version.*)$/m ) {
      printf "$1\n\n\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }
  

  # osmconvert (not triggered)
  # --------------------------
  printf "osmconvert\n";
  printf "======================================\n";
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    $cmdoutput = `$BASEPATH/tools/osmconvert/osx/osmconvert --help 2>&1`;
  }	
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $cmdoutput = `$BASEPATH\\tools\\osmconvert\\windows\\osmconvert.exe --help 2>&1`;
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    if ( ( $OSNAME eq 'linux' ) && ( $os_archbit eq '64' ) ) {
      $cmdoutput = `$BASEPATH/tools/osmconvert/linux/osmconvert64 --help 2>&1`;
    }
    else
    {
      $cmdoutput = `$BASEPATH/tools/osmconvert/linux/osmconvert32 --help 2>&1`;
    }
  }
  # Try to match
  if ( $cmdoutput =~ /^(osmconvert .*)$/m ) {
      printf "$1\n\n\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }

  
  # osmfilter (not triggered)
  # -------------------------
  printf "osmfilter - not used during build\n";
  printf "======================================\n";
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    $cmdoutput = `$BASEPATH/tools/osmfilter/osx/osmfilter --help 2>&1`;
  }	
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $cmdoutput = `$BASEPATH\\tools\\osmfilter\\windows\\osmfilter.exe --help 2>&1`;
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $cmdoutput = `$BASEPATH/tools/osmfilter/linux/osmfilter32 --help 2>&1`;
  }
  # Try to match
  if ( $cmdoutput =~ /^(osmfilter .*)$/m ) {
      printf "$1\n\n\n";
  }
  else {
      printf "PROBLEM: either tool not found or no match for version string.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$cmdoutput\n";
      printf "----------------------------\n\n\n";
  }
  

  # wget (windows directory)
  # ------------------------
  printf "GNU Wget - Windows only\n";
  printf "======================================\n";
  # Windows
  if ( $OSNAME eq 'MSWin32' ) {
     $cmdoutput = `$BASEPATH\\tools\\wget\\windows\\wget.exe --version 2>&1`;
     # Try to match
     if ( $cmdoutput =~ /(GNU Wget .*)$/m ) {
 	      printf "$1\n";
     }
     else {
        printf "PROBLEM: either tool not found or no match for version string.\n";
        printf "         see detailed command output below:\n";
        printf "----------------------------\n";
        printf "$cmdoutput\n";
        printf "----------------------------\n\n\n";
     }
     if ( $cmdoutput =~ /^(\+.*)$/m ) {
 	      printf "$1\n";
     }
  }
  printf "\n\n";
  

  # NSIS (windows directory), has to be installed on Linux
	# -------------------------------------------------------
  printf "NSIS: makensis - Windows and linux\n";
  printf "======================================\n";
  # Linux, FreeBSD, OpenBSD
  if ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
     $cmdoutput = `makensis -version 2>&1`;
     printf "MakeNSIS $cmdoutput\n";
  }
  # Windows
  elsif ( $OSNAME eq 'MSWin32' ) {
     $cmdoutput = `$BASEPATH\\tools\\NSIS\\windows\\makensis.exe /Version 2>&1`;
     printf "MakeNSIS $cmdoutput\n";
  }
  printf "\n\n";


  # bounds and sea
	# ---------------
  printf "Bounderies (bounds)\n";
  printf "======================================\n";
  $inputfile = "$BASEPATH/bounds/version.txt";
  if (open( my $filehandle, "<  $inputfile ") ) {
    while ( $lineoffile = <$filehandle> ) {
	    chomp $lineoffile;
	    print "$lineoffile\n\n\n";
    }
    close ( $filehandle );
	}
	else {
      printf "PROBLEM: either boundaries not found at all or file\n";
      printf "           $inputfile\n";
      printf "         not existing.\n";
      printf "         see detailed command output below:\n";
      printf "----------------------------\n";
      printf "$!\n";
      printf "----------------------------\n\n\n";
	}
  printf "Sea Bounderies (sea)\n";
  printf "======================================\n";
  $inputfile = "$BASEPATH/sea/version.txt";
  if (open( my $filehandle, "<  $inputfile ") ) {
    while ( $lineoffile = <$filehandle> ) {
	     chomp $lineoffile;
	     print "$lineoffile\n\n\n";
    }
    close ( $filehandle );
	}
	else {
        printf "PROBLEM: either sea boundaries not found at all or file\n";
        printf "           $inputfile\n";
        printf "         not existing.\n";
        printf "         see detailed command output below:\n";
        printf "----------------------------\n";
        printf "$!\n";
        printf "----------------------------\n\n\n";
	}
    

  # TYPViewer (windows directory), GUI tool, not used, just there for convenience

  # IMGinfo (not triggered, GUI tool)
      
  # gmapi-builder.py
    
    
  printf "\n\n";

}


# --------------------------------------------------------
# Bootstrap: load 'missing' big chunks from the Internet
# --------------------------------------------------------
sub bootstrap_environment {
  
  # Some local variables
  my $bootstrapdir = "$BASEPATH/work/bootstrap";
  my $actualurl = "";
  my $directory = "";
  my $success = 0;
  my $bs_subcmd = "";
  my $bs_boundariesurl = "";
  my $bs_seaboundariesurl = "";
  my $returnvalue = "";
  
  # Check if the bootstrap directory exists, else create it and go to it
  # --------------------------------------------------------------------
  if ( !( -e "$BASEPATH/work" ) ) {
    mkdir ( "$BASEPATH/work" );
    printf { *STDOUT } ( "\nDirectory %s created.\n\n", "$BASEPATH/work" );
  }
  if ( !( -e $bootstrapdir ) ) {
    mkdir ( $bootstrapdir );
    printf { *STDOUT } ( "\nDirectory %s created.\n\n", $bootstrapdir );
  }
  
  chdir $bootstrapdir;

  # Check for additional parameters with bootstrap
  # ----------------------------------------------
  if ( ( $#ARGV + 1 ) > 1 ) {
     $bs_subcmd    = $ARGV[ 1 ];
  }

  # handle the 'list' subcommando
  # -----------------------------
  if ( $bs_subcmd eq 'list' ) {
     printf { *STDOUT } ( "\nbootstrap SubCommando: %s: List the download URLs for the boundaries\n\n", $bs_subcmd );

     # Boundaries (bigger file)
	 printf { *STDOUT } ( "\nBoundaries (going into directory 'bounds')\n" );
	 printf { *STDOUT } ( "----------------------------------------------\n" );
     foreach $actualurl ( @boundariesurl ) {
        printf { *STDOUT } ( "$actualurl\n" );
     }

	 printf { *STDOUT } ( "\nSea Boundaries (going into directory 'sea')\n" );
	 printf { *STDOUT } ( "----------------------------------------------\n" );
     # seatiles or sea boundaries (smaller file)
     foreach $actualurl ( @seaboundariesurl ) {
        printf { *STDOUT } ( "$actualurl\n" );
     }

     printf { *STDOUT } ( "\n   we're done with listing the downloadurls... exiting ... \n\n" );
	 exit;
  }
  
  # handle the 'list' subcommando
  # -----------------------------
  elsif ( $bs_subcmd eq 'urls' ) {
     printf { *STDOUT } ( "\nbootstrap SubCommando: %s: force specific URLs for downloading\n\n", $bs_subcmd );

     # Get the URLs from the arguments
     # --------------------------------
     if ( ( $#ARGV + 1 ) >= 4 ) {
        $bs_boundariesurl    = $ARGV[ 2 ];
        $bs_seaboundariesurl = $ARGV[ 3 ];
	 }

     # Check if both URLs are given
     # -----------------------------
     if ( $bs_boundariesurl eq '' || $bs_seaboundariesurl eq '') {
        printf { *STDOUT } ( "ERROR:\n  Commando 'bootstrap urls' requieres two valid URLs as additional arguments.\n\n\n" );
        show_usage ();
        exit(1);
	 }

     # Check if the given arguments are proper and available URLs
     # ----------------------------------------------------------
     # Set the OS specific command for testing the URLs
     if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
       # OS X, Linux, FreeBSD, OpenBSD
       $command = "curl --output /dev/null --silent --fail --head --url ";
     }
     elsif ( $OSNAME eq 'MSWin32' ) {
       # Windows
       $command = "$BASEPATH/tools/wget/windows/wget.exe -q --spider ";
     }
     else {
       printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
       exit;
     }

    # Check the given URLs
    $returnvalue = system( $command . $bs_boundariesurl);
    if ( $returnvalue != 0 ) {
        printf { *STDOUT } ( "ERROR:\n  URL %s is either not valid or not available.\n\n\n", $bs_boundariesurl );
        show_usage ();
        exit(1);
	}
    $returnvalue = system( $command . $bs_seaboundariesurl);
    if ( $returnvalue != 0 ) {
        printf { *STDOUT } ( "ERROR:\n  URL %s is either not valid or not available.\n\n\n", $bs_seaboundariesurl );
        show_usage ();
        exit(1);
	}
	
	# Now we have to 'override' the array containing the downloadurls
	@boundariesurl = ( "$bs_boundariesurl" );
	@seaboundariesurl = ( "$bs_seaboundariesurl" );

  }
  
  # Check if there is an 'unknown' subcommando... if yes: exit
  elsif ( $bs_subcmd ne '' ) {
     printf { *STDOUT } ( "ERROR:\n  There was an additional unknown subcommand following 'bootstratp.\n\n\n", $bs_seaboundariesurl );
     show_usage ();
     exit(1);
  }
  
  # Try to download the latest version of the boundaries
  # ----------------------------------------------------

  # Set check variable to 'false'
  $success = 0;

  # First we take the boundaries (bigger file)
  foreach $actualurl ( @boundariesurl ) {
    
    download_url( $actualurl, "bounds.zip");
        
    # Check Return Value
    if ( $? != 0 ) {
        printf "\n\nWARNING: Downloadurl $actualurl seems not to work .... \n";
        printf "         trying anotherone if existing.\n";
    }
    else {
        printf "\n\nOK:      Downloadurl $actualurl worked.\n";
        $success = 1;
        last;
    }
  }
  
  # Loop finished let's check if we need to exit or can continue
  unless ( $success ) {
	  die ( "\n\nERROR: Unable to download the boundaries from any of the given URLs\n");
  }

  # Set check variable back to 'false'
  $success = 0;

  # Now we take the seatiles (smaller file)
  foreach $actualurl ( @seaboundariesurl ) {
    
    download_url($actualurl, "sea.zip");
    
    # Check Return Value
    if ( $? != 0 ) {
        printf "\n\nWARNING: Downloadurl $actualurl seems not to work .... \n";
        printf "         trying anotherone if existing.\n";
    }
    else {
        printf "\n\nOK:      Downloadurl $actualurl worked.\n";
        $success = 1;
        last;
    }
  }
  
  # Loop finished let's check if we need to exit or can continue
  unless ( $success ) {
	  die ( "\n\nERROR: Unable to download the seaboundaries from any of the given URLs\n\n");
  }
  
  # Check the downloaded zip files for consistency
  # -----------------------------------------------
  foreach $directory ( "bounds", "sea" ) {
  
	# Test the Archive
	# ----------------
	# Set the commands depending on the OS we're running on
	if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
       # OS X, Linux, FreeBSD, OpenBSD
       $command = "unzip -t -q $bootstrapdir/$directory.zip";
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
       # Windows
       $command = "$BASEPATH/tools/zip/windows/7-Zip/7za.exe t $bootstrapdir/$directory.zip";
    }
    else {
       printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
    }
    
    # Run the command
    process_command ( $command );

    # Check Return Value
    if ( $? != 0 ) {
        die "\n\nERROR: Downloaded Archive $directory.zip seems be corrupt .... exiting now\n\n";
    }
  }
    
  # Extract it into the correct location (after cleaning up the old stuff there)
  # ----------------------------------------------------------------------------  
  foreach $directory ( "bounds", "sea" ) {
	  	  
	# Recreate the needed directory in an empty state
	# -----------------------------------------------
    rmtree ( "$BASEPATH/$directory",    0, 1 );
    sleep 1;
    mkpath ( "$BASEPATH/$directory" );
	
	# Unzip the stuff
	# ----------------
	# Set the commands depending on the OS we're running on
	if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
       # OS X, Linux, FreeBSD, OpenBSD
       $command = "unzip -j -q $bootstrapdir/$directory.zip -d $BASEPATH/$directory";
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
       # Windows
       $command = "$BASEPATH/tools/zip/windows/7-Zip/7za.exe e $bootstrapdir/$directory.zip -y -o$BASEPATH/$directory";
    }
    else {
       printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
    }
    
    # Run the command
    process_command ( $command );

	# Clean an eventually created unneeded subdirectory
	if ( -e "$BASEPATH/$directory/$directory" ) {
       rmtree ( "$BASEPATH/$directory/$directory", 0, 0 );
    }

    # Cleanup the files we've downloaded
    unlink ( "$bootstrapdir/$directory.zip" );

  }
}


# -----------------------------------------
# Basic Check of the Environment
# -----------------------------------------
sub check_environment {
 
  my $directory = "";
  my $count = 0;
    
  # Print out what we're doing
  printf { *STDOUT } ( "\nChecking the Development Environment...\n" );

  # Check the existence of the 'install' directory and create it if necessary
  $directory = "$BASEPATH/install";
  if ( !( -e $directory ) ) {
     mkdir ( $directory );
     printf { *STDOUT } ( "Directory %s created.\n", $directory );
  }

  # Check the existence of the 'work' directory and create it if necessary
  $directory = "$BASEPATH/work";
  if ( !( -e $directory ) ) {
     mkdir ( $directory );
     printf { *STDOUT } ( "Directory %s created.\n", $directory );
  }

  # Check for the existence of the bounds directory and the needed files in it
  $directory = "$BASEPATH/bounds";
  if ( !( -e $directory ) ) {
      die ( "\nERROR:\nThe directory $directory is missing.\nDid you run the Action 'bootstrap' to get all needed files ?\n\n" );
  }
  $count = 0;
  ++$count while glob "$directory/bounds_*_*.bnd";
  if ( $count < 10000 ) {
    die ( "\nERROR:\nThere are only $count bounds_*_*.bnd files in $directory.\nDid you run the Action 'bootstrap' to get all needed files ?\n\n" );  
  }

  # Check for the existence of the sea directory and the needed files in it
  $directory = "$BASEPATH/sea";
  if ( !( -e $directory ) ) {
      die ( "\nERROR:\nThe directory $directory is missing.\nDid you run the Action 'bootstrap' to get all needed files ?\n\n" );
  }
  $count = 0;
  ++$count while glob "$directory/sea_*_*.osm.pbf";
  if ( $count < 5000 ) {
    die ( "\nERROR:\nThere are only $count sea_*_*.osm.pbf files in $directory.\nDid you run the Action 'bootstrap' to get all needed files ?\n\n" );  
  }

  # Get an empty line before continuing
  printf { *STDOUT } ( "\n" );

}

# -----------------------------------------
# Put the release numbers together
# -----------------------------------------
sub get_release {

  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = "";

  # Try to get the creation time from the map data file
  my $filename_source       = "$WORKDIR/$mapname.osm.pbf";
  if ( -e $filename_source ) {
     
     # File exists, get creation date and it's components
     my $filename_source_mtime = ( stat ( $filename_source ) )[ 9 ];
     ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime ( $filename_source_mtime );
    
  }
  else {
    
     # no File, get actual date and it's components
     ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime ();
    
  }
  
  # Create the needed release numbers
  $releasestring  = sprintf ( "%d.%02d", ( $year - 100 ), ( $mon + 1 ) );
  $releasenumeric = sprintf ( "%d%02d",  ( $year - 100 ), ( $mon + 1 ) );

}

# -----------------------------------------
# Check Operating systems for 64bit
# -----------------------------------------
sub get_osdetails {
  
  # Get systemdetails into array
  my @uname = uname();

  # Get the different parts from uname
  $os_sysname  = $uname[0];
  $os_nodename = $uname[1];
  $os_release  = $uname[2];
  $os_version  = $uname[3];
  $os_machine  = $uname[4];
  
  # If Linux or OpenBSD
  if ( $OSNAME eq 'linux' || $OSNAME eq 'OpenBSD' ) {

    # Check for 64bit String
    if ( $os_machine eq 'x86_64' || $os_machine eq 'amd64' ) {
      $os_archbit = "64";
    }
  }

}

# -----------------------------------------
# Show action summary
# -----------------------------------------
sub show_actionsummary {
  
  # delete trailing spaces from the action description
  my $tmpstring = $actiondesc;
  $tmpstring =~   s/^\s+//;

  # Print out the Information about the choosen action and map
  printf { *STDOUT }     ( "Action:     %s\n",      $actionname );
  printf { *STDOUT }     ( "            %s\n",      $tmpstring );
  if ( $mapid == -1 ) {
    printf { *STDOUT }   ( "Map         n/a\n" );
  }
  else {
    printf { *STDOUT }   ( "Map:        %s (%s)\n", $mapname, $mapid );
    printf { *STDOUT }   ( "Language:   %s (%s)\n", $langdesc, $maplang );
    printf { *STDOUT }   ( "CodePage:   %s\n",      $mapcodepage );
    printf { *STDOUT }   ( "Typ file:   %s.TYP\n",  $maptypfile );
    printf { *STDOUT }   ( "Style Dir:  %s\n",  $mapstyledir );
    printf { *STDOUT }   ( "Elevation:  %s m\n",    $ele );
    if ( $maptype == 3 ) {
      printf { *STDOUT } ( "Map type:   downloadable OSM extract\n" );
    }
    elsif (  $maptype == 2 ) {
      printf { *STDOUT } ( "Map type:   own extract, parent map needed\n" );      
      printf { *STDOUT } ( "Parent Map: %s\n",      $mapparent );
    }
    elsif (  $maptype == 1 ) {
      printf { *STDOUT } ( "Map type:   parent map\n" );      
    }
    if ( $nametaglist ne $EMPTY ) {
      printf { *STDOUT } ( "Ntl:        name-tag-list=%s\n", $nametaglist );  
    }
	if ( $dempath ne $EMPTY ) {
	  printf { *STDOUT } ( "DEM path:   %s\n", $dempath );
	  printf { *STDOUT } ( "DEM type:   %s\n", $demtype );
	  printf { *STDOUT } ( "DEM dists:  %s\n", $demdists );
	}
    if ( ( $releasestring ne $EMPTY ) && ( $releasenumeric ne $EMPTY ) ) {
        printf { *STDOUT }   ( "Release:    %s / %s\n",$releasestring,$releasenumeric );
    }
  }

}

# -----------------------------------------
# Show wrong target warning
# -----------------------------------------
sub show_wrongtargetwarning {

  # Let the user know about the wrong combination of maps and actions
  printf { *STDOUT } ( "\n" ); 
  printf { *STDOUT } ( "\nWarning !   the action '%s' is not supposed to run on this map of type %s.", $actionname, $maptype ); 
  printf { *STDOUT } ( "\n            The following can happen:" ); 
  printf { *STDOUT } ( "\n            - the process fails with an error" ); 
  printf { *STDOUT } ( "\n            - the process is very time and resource consuming" ); 
  printf { *STDOUT } ( "\n            - the result is not what you expect" ); 
  printf { *STDOUT } ( "\n" ); 
  printf { *STDOUT } ( "\n            If you are not sure what you are doing you better stop now with ctrl-C." ); 
  printf { *STDOUT } ( "\n            Else just stand by for 10 seconds and wait until the process continues automatically." ); 
  printf { *STDOUT } ( "\n\n" ); 

  # Sleep for 10 seconds
      sleep 10;

  # User did not stop, therefore let's continue and let user know
  printf { *STDOUT } ( "\nContinuing now ..." ); 
  printf { *STDOUT } ( "\n\n" ); 
 
}

# -----------------------------------------
# Show short usage
# -----------------------------------------
sub show_usage {

  # Print the Usage
  printf { *STDOUT } (
    "Usage:\n"
      . "perl $programName [--ram=<value>] [--cores=<value>] [--ele=<value>] \\\n"
      . "           [--typfile=\"<filename>\"] [--style=\"<dirname>\"] \\\n"
      . "           [--language=\"<lang>\"] [--unicode] [--ntl=\"<name-tag-list>\"] \\\n"
      . "           [--downloadbar] [--downloadspeed=<value>] [--continuedownload]\\\n"
      . "           [--dempath=<path>]\\\n"
      . "           <Action> <ID> | <Code> | <Map> [PPO] ... [PPO]\n"
      . "  or\n"
      . "perl $programName bootstrap [urls <url_bounds> <url_sea>]\n"
      . "perl $programName bootstrap list\n\n"
      . "  or for getting help:\n"
      . "perl $programName -? | -h\n"
      . "\n\n"
  );

}


# -----------------------------------------
# Show complete help
# -----------------------------------------
sub show_help {

  # Show the sort Usage
  show_usage ();
  
  # Print the details of the help
  printf { *STDOUT } (
      "Examples:\n"
      . "perl $programName                              bootstrap\n"
      . "perl $programName                              build     Freizeitkarte_Hamburg\n"
      . "perl $programName  --ram=1536    --cores=2     build     Freizeitkarte_Hamburg\n"
      . "perl $programName  --ram=6000                  build     5815\n"
      . "perl $programName  --ram=6000    --cores=max   build     5815\n"
      . "perl $programName  --ram=6000    --cores=max   build     Freizeitkarte_Oesterreich  DEXTENDEDROUTING\n\n"
      . "Options:\n"
      . "--ram      = javaheapsize in MB (join, split, build) (default = %d)\n"
      . "--cores    = max. number of CPU cores (build) (1, 2, ..., max; default = %d)\n"
      . "--ele      = equidistance of elevation lines (fetch_ele) (10, 20; default = 20)\n"
      . "--typfile  = filename of a valid typfile to be used (build, gmap, nsis, gmapsupp, imagedir, typ) (default = freizeit.TYP)\n"
      . "--style    = name of the style to be used, must be a directory below styles (default = fzk)\n"
      . "--language = overwrite the default language of a map (en=english, de=german);\n"
      . "             if you build a map for another language than the map's default language,\n"
      . "             this option needs to be set for all subcommands, else it swaps back to the default language and possibly fails.\n"
      . "--unicode  = Build the map in unicode (CP65001) instead of in the native codepage of the map language.\n"
      . "                --unicode\n"
      . "--ntl      = overwrite the default name-tag-list for the mkgmap run (name) with a specific list, e.g.\n"
      . "                --ntl=\"name:en,int_name,name\"\n"
      . "             Please check mkgmap documentation for more information.\n"
      . "--downloadbar\n"
      . "           = Show a download progress bar during actions 'bootstrap', 'fetch_osm' and 'fetch_ele'.\n"
      . "                --downloadbar\n"
      . "--downloadspeed\n"
      . "           = Set speed limit for downloads during actions 'bootstrap', 'fetch_osm' and 'fetch_ele'.\n"
      . "             Setting speed limit in number of bytes:\n"
      . "                --downloadspeedlimit=15\n"
      . "             You can also set the speed limit in kilobytes (k), megabytes (m) or gigabytes (g) by using the correct character, e.g.:\n"
      . "                --downloadspeedlimit=15m\n"
      . "--continuedownload\n"
      . "           = try to continue interrupted downloads for actions 'fetch_osm' and 'fetch_ele'.\n"
      . "                --continuedownload\n"
      . "             Restrictions:\n"
      . "             - can only work if you don't use the 'create' action, which cleans out any files from the working directories\n"
      . "             - using this option on fully completed downloads will fail to download anything new.\n"
      . "             - not guaranteed to work always and might create data garbage, but worth a try on huge downloads\n"
	  . "--dempath\n"
	  . "           = specify a directory or ZIP file with HGT files used to add a Digital Elevation Model subfile to the map (build).\n"
	  . "                --dempath=D:/fzk/hgtfiles\n"
	  . "                --dempath=D:/fzk/hgtfiles/view3.zip\n"
	  . "             N.B. On Windows, use forward slashes.\n"
      . "             Please check mkgmap documentation for more information.\n"
      . "\n"
	  . "--demtype\n"
	  . "           = specify the resolution of the HGT file in arc seconds. Supported resolutions are 1 and 3.\n"
	  . "             Used to define default demdist values.\n"
	  . "                --demtype=1\n"
	  . "                --demtype=3\n"
      . "\n"
	  . "--demdists\n"
	  . "           = Define dem-dists values for mkgmap in case --demtype is not set.\n"
	  . "                --demdists=\"9942,19884,29826,39768,49710,59652,69594,79536\"\n"
      . "             Please check mkgmap documentation for more information.\n"
      . "\n"
      . "PPO        = preprocessor options (multiple possible), to be invoked with D<option>\n"
      . "\n"
      . "Arguments:\n"
      . "Action     = Action to be processed\n"
      . "ID         = ID of the to processed map\n"
      . "Code       = Code of the to processed map\n"
      . "Map        = Name of the to be processed map\n\n",
    $javaheapsize, $cores
  );
  
  my $printdelimiter = $EMPTY;
  printf { *STDOUT } ( "Actions:\n" );
  foreach my $i ( 0 .. $#actions ) {
    if ( ( ( $actions[ $i ][ $ACTIONOPT ] eq 'optional' ) && $optional ) || $actions[ $i ][ $ACTIONOPT ] ne 'optional') {
      if ( ( $actions[ $i ][ $ACTIONOPT ] eq 'optional' ) && $optional && ( $printdelimiter ne 'done' ) ) {
        printf { *STDOUT } ( "\n" );
        $printdelimiter = 'done';
      }
      printf { *STDOUT } ( "%-10s = %s\n", $actions[ $i ][ $ACTIONNAME ], $actions[ $i ][ $ACTIONDESC ] );
    }
  }
#  if ( $optional ) {
#    printf { *STDOUT } ( "\n" );
#    foreach my $i ( 10 .. 21 ) {
#      printf { *STDOUT } ( "%-10s = %s\n", $actions[ $i ][ $ACTIONNAME ], $actions[ $i ][ $ACTIONDESC ] );
#    }
#  }
  printf { *STDOUT } ( "\nID = Code = Map  (default language):\n" );

  for my $mapdata ( @maps ) {
    if ( $optional ) {
      # alle Lï¿½nder und Regionen
      if ( @$mapdata[ $MAPID ] == -1 ) {
        printf { *STDOUT } ( "\n%s:\n", @$mapdata[ $MAPNAME ] );    # Kommentar
      }
      else {
        printf { *STDOUT } ( "%s = %-26s = %-50s(%s)\n", @$mapdata[ $MAPID ], @$mapdata[ $MAPCODE ], @$mapdata[ $MAPNAME ], @$mapdata[ $MAPLANG ] );
      }
    }
    else {
      # nur ausgewaehlte Karten
      if (   ( ( @$mapdata[ $MAPID ] <= 5825 ) && ( @$mapdata[ $MAPID ] >= 5810 ) )  # Bundesländer
        || ( @$mapdata[ $MAPID ] == 6276 )                                        # Deutschland
        || ( @$mapdata[ $MAPID ] == 6208 )                                        # Dänemark
        || ( @$mapdata[ $MAPID ] == 6616 )                                        # Polen
        || ( @$mapdata[ $MAPID ] == 6203 )                                        # Tschechien
        || ( @$mapdata[ $MAPID ] == 6040 )                                        # Österreich
        || ( @$mapdata[ $MAPID ] == 6756 )                                        # Schweiz
        || ( @$mapdata[ $MAPID ] == 7010 )                                        # Alpen
        || ( @$mapdata[ $MAPID ] == 6250 )                                        # Frankreich
        || ( @$mapdata[ $MAPID ] == 6442 )                                        # Luxemburg
        || ( @$mapdata[ $MAPID ] == 6056 )                                        # Belgien
        || ( @$mapdata[ $MAPID ] == 6528 )                                        # Niederlande
        || ( @$mapdata[ $MAPID ] == 6752 )                                        # Schweden
        )
      {
        printf { *STDOUT } ( "%s = %-26s = %-50s(%s)\n", @$mapdata[ $MAPID ], @$mapdata[ $MAPCODE ], @$mapdata[ $MAPNAME ], @$mapdata[ $MAPLANG ] );
      }
    }
  }
  printf { *STDOUT } ( "\n" );

#  exit ( 1 );
}

