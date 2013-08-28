#!/usr/bin/perl
# ---------------------------------------
# Program : mt.pl (map tool)
# Version : siehe unten
#
# Copyright (C) 2011-2013 Klaus Tockloth <Klaus.Tockloth@googlemail.com>
# - modified for Ubuntu through GVE
#
# Programmcode formatiert mit "perltidy".
# ---------------------------------------

use strict;
use warnings;
use English '-no_match_vars';

use Cwd;
use File::Copy;
use File::Path;
use File::Basename;
use Getopt::Long;
#use Data::Dumper;

my @actions = (
  # 'Aktion',  'Beschreibung'
  [ 'create',    '1.  (re)create all directories' ,                        '-' ],
  [ 'fetch_osm', '2a. fetch osm data from url' ,                           '-' ],
  [ 'fetch_ele', '2b. fetch elevation data from url' ,                     '-' ],
  [ 'join',      '3.  join osm and elevation data' ,                       '-' ],
  [ 'split',     '4.  split map data into tiles' ,                         '-' ],
  [ 'build',     '5.  build map files (img, mdx, tdb)' ,                   '-' ],
  [ 'gmap',      '6.  create gmap file (for BaseCamp OS X, Windows)' ,     '-' ],
  [ 'nsis',      '6.  create nsis installer (for BaseCamp Windows)' ,      '-' ],
  [ 'gmapsupp',  '6.  create gmapsupp image (for GPS receiver)' ,          '-' ],
  [ 'imagedir',  '6.  create image directory (e.g. for QLandkarte)' ,      '-' ],

  # Optional
  [ 'cfg',        'A. create individual cfg file' ,                        'optional' ],
  [ 'typ',        'B. create individual typ file from master' ,            'optional' ],
  [ 'compiletyp', 'B. compile TYP files out of text files' ,               'optional' ],
  [ 'nsicfg',     'C. create nsi configuration file (for NSIS compiler)' , 'optional' ],
  [ 'nsiexe',     'C. create nsi installer exe (via NSIS compiler)' ,      'optional' ],
  [ 'gmap2',      'D. create gmap file (for BaseCamp OS X, Windows)' ,     'optional' ],
  [ 'bim',        'E. build images: create, fetch_*, join, split, build' , 'optional' ],
  [ 'bam',        'F. build all maps: gmap, nsis, gmapsupp, imagedir' ,    'optional' ],
  [ 'zip',        'G. zip all maps' ,                                      'optional' ],
  [ 'regions',    'H. extract regions from Europe data' ,                  'optional' ],
  [ 'fetch_map',  'I. fetch map data from Europe directory' ,              'optional' ],
  [ 'checkurl',   'J. Check all download URLs for existence' ,             'optional' ],
);

my @supportedlanguages = (
  # 'code', 'Beschreibung'
  # Iso639-1
  [ 'de', 'Deutsch' ],
  [ 'en', 'English' ],
  [ 'fr', 'French' ]
);

# languages that are always in the TYP files (FR falls out if another language has to go in)
my @typfilelangfixed = (
  "xx",    # Unspecified
  "de",    # Deutsch
  "en",    # Englisch
  "fr"     # Französich
);

# Define the download base URLs for the Elevation Data
my %elevationbaseurl = (
  'ele10' => "http://freizeitkarte-osm.de/maps/Development/ele_10_100_200",
  'ele25' => "http://freizeitkarte-osm.de/maps/Development/ele_25_250_500",
  );

my @maps = (
  # ID, 'Karte', 'URL der Quelle', 'Code', 'language'

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

  # Länder, Ländercodes: 6000 + ISO-3166 (numerisch)
  [ -1,   'Europaeische Laender',                 'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 6008, 'Freizeitkarte_ALB',                    'http://download.geofabrik.de/europe/albania-latest.osm.pbf',                                        'ALB',                      'en', 'Freizeitkarte_Albanien',                  3, 'NA'             ],
  [ 6020, 'Freizeitkarte_AND',                    'http://download.geofabrik.de/europe/andorra-latest.osm.pbf',                                        'AND',                      'en', 'Freizeitkarte_Andorra',                   3, 'NA'             ],
  [ 6112, 'Freizeitkarte_BLR',                    'http://download.geofabrik.de/europe/belarus-latest.osm.pbf',                                        'BLR',                      'en', 'Freizeitkarte_Belarus',                   3, 'NA'             ],
  [ 6056, 'Freizeitkarte_BEL',                    'http://download.geofabrik.de/europe/belgium-latest.osm.pbf',                                        'BEL',                      'en', 'Freizeitkarte_Belgien',                   3, 'NA'             ],
  [ 6070, 'Freizeitkarte_BIH',                    'http://download.geofabrik.de/europe/bosnia-herzegovina-latest.osm.pbf',                             'BIH',                      'en', 'Freizeitkarte_Bosnien-Herzegowina',       3, 'NA'             ],
  [ 6100, 'Freizeitkarte_BGR',                    'http://download.geofabrik.de/europe/bulgaria-latest.osm.pbf',                                       'BGR',                      'en', 'Freizeitkarte_Bulgarien',                 3, 'NA'             ],
  [ 6208, 'Freizeitkarte_DNK',                    'http://download.geofabrik.de/europe/denmark-latest.osm.pbf',                                        'DNK',                      'en', 'Freizeitkarte_Daenemark',                 3, 'NA'             ],
  [ 6276, 'Freizeitkarte_DEU',                    'http://download.geofabrik.de/europe/germany-latest.osm.pbf',                                        'DEU',                      'de', 'Freizeitkarte_Deutschland',               3, 'NA'             ],
  [ 6233, 'Freizeitkarte_EST',                    'http://download.geofabrik.de/europe/estonia-latest.osm.pbf',                                        'EST',                      'en', 'Freizeitkarte_Estland',                   3, 'NA'             ],
  [ 6234, 'Freizeitkarte_FRO',                    'http://download.geofabrik.de/europe/faroe-islands-latest.osm.pbf',                                  'FRO',                      'en', 'Freizeitkarte_Faeroeer',                  3, 'NA'             ],
  [ 6246, 'Freizeitkarte_FIN',                    'http://download.geofabrik.de/europe/finland-latest.osm.pbf',                                        'FIN',                      'en', 'Freizeitkarte_Finnland',                  3, 'NA'             ],
  [ 6250, 'Freizeitkarte_FRA',                    'http://download.geofabrik.de/europe/france-latest.osm.pbf',                                         'FRA',                      'en', 'Freizeitkarte_Frankreich',                3, 'NA'             ],
  [ 6826, 'Freizeitkarte_GBR',                    'http://download.geofabrik.de/europe/great-britain-latest.osm.pbf',                                  'GBR',                      'en', 'Freizeitkarte_Grossbritannien',           3, 'NA'             ],
  [ 6300, 'Freizeitkarte_GRC',                    'http://download.geofabrik.de/europe/greece-latest.osm.pbf',                                         'GRC',                      'en', 'Freizeitkarte_Griechenland',              3, 'NA'             ],
  [ 6833, 'Freizeitkarte_IMN',                    'http://download.geofabrik.de/europe/isle-of-man-latest.osm.pbf',                                    'IMN',                      'en', 'Freizeitkarte_Insel-Man',                 3, 'NA'             ],
  [ 6372, 'Freizeitkarte_IRL',                    'http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf',                   'IRL',                      'en', 'Freizeitkarte_Irland',                    3, 'NA'             ],
  [ 6352, 'Freizeitkarte_ISL',                    'http://download.geofabrik.de/europe/iceland-latest.osm.pbf',                                        'ISL',                      'en', 'Freizeitkarte_Island',                    3, 'NA'             ],
  [ 6380, 'Freizeitkarte_ITA',                    'http://download.geofabrik.de/europe/italy-latest.osm.pbf',                                          'ITA',                      'en', 'Freizeitkarte_Italien',                   3, 'NA'             ],
  [ 6680, 'Freizeitkarte_KOSOVO',                 'http://download.geofabrik.de/europe/kosovo-latest.osm.pbf',                                         'KOSOSVO',                  'en', 'Freizeitkarte_Kosovo',                    3, 'NA'             ],
  [ 6191, 'Freizeitkarte_HRV',                    'http://download.geofabrik.de/europe/croatia-latest.osm.pbf',                                        'HRV',                      'en', 'Freizeitkarte_Kroatien',                  3, 'NA'             ],
  [ 6428, 'Freizeitkarte_LVA',                    'http://download.geofabrik.de/europe/latvia-latest.osm.pbf',                                         'LVA',                      'en', 'Freizeitkarte_Lettland',                  3, 'NA'             ],
  [ 6438, 'Freizeitkarte_LIE',                    'http://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf',                                  'LIE',                      'en', 'Freizeitkarte_Liechtenstein',             3, 'NA'             ],
  [ 6440, 'Freizeitkarte_LTU',                    'http://download.geofabrik.de/europe/lithuania-latest.osm.pbf',                                      'LTU',                      'en', 'Freizeitkarte_Litauen',                   3, 'NA'             ],
  [ 6442, 'Freizeitkarte_LUX',                    'http://download.geofabrik.de/europe/luxembourg-latest.osm.pbf',                                     'LUX',                      'en', 'Freizeitkarte_Luxemburg',                 3, 'NA'             ],
  [ 6807, 'Freizeitkarte_MKD',                    'http://download.geofabrik.de/europe/macedonia-latest.osm.pbf',                                      'MKD',                      'en', 'Freizeitkarte_Mazedonien',                3, 'NA'             ],
  [ 6470, 'Freizeitkarte_MLT',                    'http://download.geofabrik.de/europe/malta-latest.osm.pbf',                                          'MLT',                      'en', 'Freizeitkarte_Malta',                     3, 'NA'             ],
  [ 6498, 'Freizeitkarte_MDA',                    'http://download.geofabrik.de/europe/moldova-latest.osm.pbf',                                        'MDA',                      'en', 'Freizeitkarte_Moldawien',                 3, 'NA'             ],
  [ 6492, 'Freizeitkarte_MCO',                    'http://download.geofabrik.de/europe/monaco-latest.osm.pbf',                                         'MCO',                      'en', 'Freizeitkarte_Monaco',                    3, 'NA'             ],
  [ 6499, 'Freizeitkarte_MNE',                    'http://download.geofabrik.de/europe/montenegro-latest.osm.pbf',                                     'MNE',                      'en', 'Freizeitkarte_Montenegro',                3, 'NA'             ],
  [ 6504, 'Freizeitkarte_MAR',                    'http://download.geofabrik.de/africa/morocco-latest.osm.pbf',                                        'MAR',                      'en', 'Freizeitkarte_Marokko',                   3, 'NA'             ],
  [ 6528, 'Freizeitkarte_NLD',                    'http://download.geofabrik.de/europe/netherlands-latest.osm.pbf',                                    'NLD',                      'en', 'Freizeitkarte_Niederlande',               3, 'NA'             ],
  [ 6578, 'Freizeitkarte_NOR',                    'http://download.geofabrik.de/europe/norway-latest.osm.pbf',                                         'NOR',                      'en', 'Freizeitkarte_Norwegen',                  3, 'NA'             ],
  [ 6040, 'Freizeitkarte_AUT',                    'http://download.geofabrik.de/europe/austria-latest.osm.pbf',                                        'AUT',                      'de', 'Freizeitkarte_Oesterreich',               3, 'NA'             ],
  [ 6616, 'Freizeitkarte_POL',                    'http://download.geofabrik.de/europe/poland-latest.osm.pbf',                                         'POL',                      'en', 'Freizeitkarte_Polen',                     3, 'NA'             ],
  [ 6620, 'Freizeitkarte_PRT',                    'http://download.geofabrik.de/europe/portugal-latest.osm.pbf',                                       'PRT',                      'en', 'Freizeitkarte_Portugal',                  3, 'NA'             ],
  [ 6642, 'Freizeitkarte_ROU',                    'http://download.geofabrik.de/europe/romania-latest.osm.pbf',                                        'ROU',                      'en', 'Freizeitkarte_Rumaenien',                 3, 'NA'             ],
  [ 6752, 'Freizeitkarte_SWE',                    'http://download.geofabrik.de/europe/sweden-latest.osm.pbf',                                         'SWE',                      'en', 'Freizeitkarte_Schweden',                  3, 'NA'             ],
  [ 6756, 'Freizeitkarte_CHE',                    'http://download.geofabrik.de/europe/switzerland-latest.osm.pbf',                                    'CHE',                      'de', 'Freizeitkarte_Schweiz',                   3, 'NA'             ],
  [ 6688, 'Freizeitkarte_SRB',                    'http://download.geofabrik.de/europe/serbia-latest.osm.pbf',                                         'SRB',                      'en', 'Freizeitkarte_Serbien',                   3, 'NA'             ],
  [ 6703, 'Freizeitkarte_SVK',                    'http://download.geofabrik.de/europe/slovakia-latest.osm.pbf',                                       'SVK',                      'en', 'Freizeitkarte_Slowakei',                  3, 'NA'             ],
  [ 6705, 'Freizeitkarte_SVN',                    'http://download.geofabrik.de/europe/slovenia-latest.osm.pbf',                                       'SVN',                      'en', 'Freizeitkarte_Slowenien',                 3, 'NA'             ],
  [ 6724, 'Freizeitkarte_ESP',                    'http://download.geofabrik.de/europe/spain-latest.osm.pbf',                                          'ESP',                      'en', 'Freizeitkarte_Spanien',                   3, 'NA'             ],
  [ 6203, 'Freizeitkarte_CZE',                    'http://download.geofabrik.de/europe/czech-republic-latest.osm.pbf',                                 'CZE',                      'en', 'Freizeitkarte_Tschechien',                3, 'NA'             ],
  [ 6792, 'Freizeitkarte_TUR',                    'http://download.geofabrik.de/europe/turkey-latest.osm.pbf',                                         'TUR',                      'en', 'Freizeitkarte_Tuerkei',                   3, 'NA'             ],
  [ 6804, 'Freizeitkarte_UKR',                    'http://download.geofabrik.de/europe/ukraine-latest.osm.pbf',                                        'UKR',                      'en', 'Freizeitkarte_Ukraine',                   3, 'NA'             ],
  [ 6348, 'Freizeitkarte_HUN',                    'http://download.geofabrik.de/europe/hungary-latest.osm.pbf',                                        'HUN',                      'en', 'Freizeitkarte_Ungarn',                    3, 'NA'             ],
  [ 6196, 'Freizeitkarte_CYP',                    'http://download.geofabrik.de/europe/cyprus-latest.osm.pbf',                                         'CYP',                      'en', 'Freizeitkarte_Zypern',                    3, 'NA'             ],
  
  [ -1,   'Andere Laender',                       'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 6032, 'Freizeitkarte_ARG',                    'http://download.geofabrik.de/south-america/argentina-latest.osm.pbf',                               'ARG',                      'de', 'no_old_name',                             3, 'NA'             ],


  # Andere Regionen
#  [ -1,   'Andere Regionen',                      'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
#  [ 7010, 'Freizeitkarte_ALPS-SMALL',             'http://download.geofabrik.de/europe/alps-latest.osm.pbf',                                           'ALPS-SMALL',               'en', 'Freizeitkarte_Alpen',                     3, 'NA'             ],
#  [ 7020, 'Freizeitkarte_AZORES',                 'http://download.geofabrik.de/europe/azores-latest.osm.pbf',                                         'AZORES',                   'en', 'Freizeitkarte_Azoren',                    3, 'NA'             ],
#  [ 7030, 'Freizeitkarte_BRITISH-ISLES',          'http://download.geofabrik.de/europe/british-isles-latest.osm.pbf',                                  'BRITISH-ISLES',            'en', 'Freizeitkarte_Britische-Inseln',          3, 'NA'             ],
#  [ 7040, 'Freizeitkarte_IRELAND-ISLAND',         'http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf',                   'IRELAND-ISLAND',           'en', 'Freizeitkarte_Irland-Insel',              3, 'NA'             ],
#  [ 7050, 'Freizeitkarte_EUROP-RUSSIA',           'http://download.geofabrik.de/europe/russia-european-part-latest.osm.pbf',                           'EUROP-RUSSIA',             'en', 'Freizeitkarte_Euro-Russland',             3, 'NA'             ],
#  [ 7060, 'Freizeitkarte_CANARY-ISLANDS',         'http://download.geofabrik.de/africa/canary-islands-latest.osm.pbf',                                 'CANARY-ISLANDS',           'en', 'Freizeitkarte_Kanarische-Inseln',         3, 'NA'             ],

  # PLUS Länder, Ländercodes: 7000 + ISO-3166 (numerisch)
  [ -1,   'Freizeitkarte PLUS Länder',            'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 7040, 'Freizeitkarte_AUT+',                   'NA',                                        														   'AUT+',                     'de', 'no_old_name',               			    2, 'EUROPE'         ],
  [ 7756, 'Freizeitkarte_CHE+',                   'NA',                                    															   'CHE+',                     'de', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7276, 'Freizeitkarte_DEU+',                   'NA',                                        														   'DEU+',                     'de', 'no_old_name',                             2, 'EUROPE'         ],
  [ 7032, 'Freizeitkarte_ARG+',                   'NA',                                        														   'ARG+',                     'en', 'no_old_name',                             2, 'SOUTHAMERICA'   ],



  # Sonderkarten wie z.B. FZK-eigene Extrakte (alle ohne geofabrik-Download (NA = Not Applicable); Ausnahme Europa)
  [ -1,   'Freizeitkarte Regionen',               'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 8888, 'Freizeitkarte_EUROPE',                 'http://download.geofabrik.de/europe-latest.osm.pbf',                                                'EUROPE',                   'en', 'no_old_name',                             1, 'NA'             ],
  [ 8010, 'Freizeitkarte_GBR_IRL',                'NA',                                                                                                'GBR_IRL',                  'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8020, 'Freizeitkarte_ALPS',                   'NA',                                                                                                'ALPS',                     'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8030, 'Freizeitkarte_DNK_NOR_SWE_FIN',        'NA',                                                                                                'DNK_NOR_SWE_FIN',          'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8040, 'Freizeitkarte_BEL_NLD_LUX',            'NA',                                                                                                'BEL_NLD_LUX',              'en', 'no_old_name',                             2, 'EUROPE'         ],
  [ 8050, 'Freizeitkarte_ESP_PRT',                'NA',                                                                                                'ESP_PRT',                  'en', 'no_old_name',                             2, 'EUROPE'         ],

  [ 8889, 'Freizeitkarte_SOUTHAMERICA',           'http://download.geofabrik.de/south-america-latest.osm.pbf',                                         'SOUTHAMERICA',             'en', 'no_old_name',                             1, 'NA'             ],
  [ 8510, 'Freizeitkarte_MISIONES',               'NA',                                                                                                'MISIONES',                 'de', 'no_old_name',                             2, 'SOUTHAMERICA'   ],
  [ 8520, 'Freizeitkarte_SAOPAULO',               'NA',                                                                                                'SAOPAULO',                 'de', 'no_old_name',                             2, 'SOUTHAMERICA'   ],

  # Andere Regionen
#  [ -1,   'Andere Regionen',                      'URL',                                                                                               'Code',               'Language', 'oldName',                            'Type', 'Parent'         ],
  [ 9010, 'Freizeitkarte_RUS_EUR',                 'http://download.geofabrik.de/europe/russia-european-part-latest.osm.pbf',                           'RUS_EUR',                 'en', 'Freizeitkarte_Euro-Russland',             3, 'NA'             ],
  [ 9020, 'Freizeitkarte_ESP_CANARIAS',            'http://download.geofabrik.de/africa/canary-islands-latest.osm.pbf',                                 'ESP_CANARIAS',            'en', 'Freizeitkarte_Kanarische-Inseln',         3, 'NA'             ],

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

my $LANGCODE = 0;
my $LANGDESC = 1;

my $VERSION = '1.3.2 - 2013/05/10';

# Maximale Speichernutzung (Heapsize im MB) beim Splitten und Compilieren
my $javaheapsize = 1536;

# Maximale Anzahl an zu benutzenden CPU-Kernen beim Compilieren (mkgmap)
my $max_jobs = $EMPTY;

# Maximale Anzahl an zu benutzenden CPU-Kernen beim Splitten (splitter)
my $max_threads = $EMPTY;

# basepath
my $BASEPATH = getcwd ( $PROGRAM_NAME );

# program startup
# ---------------
my $programName = basename ( $PROGRAM_NAME );
my $programInfo = "$programName - Map Tool for creating Garmin maps";
printf { *STDOUT } ( "\n%s, %s\n\n", $programInfo, $VERSION );

# OS X = 'darwin'; Windows = 'MSWin32'; Linux = 'linux'; FreeBSD = 'freebsd'; OpenBSD = 'openbsd';
# printf { *STDOUT } ( "OSNAME = %s\n", $OSNAME );
# printf { *STDOUT } ( "PERL_VERSION = %s\n", $PERL_VERSION );
# printf { *STDOUT } ( "BASEPATH = %s\n\n", $BASEPATH );

# command line parameters
my $help     = $EMPTY;
my $optional = $EMPTY;
my $ram      = $EMPTY;
my $cores    = 2;
my $ele      = 25;
my $clm      = 1;
my $typfile  = $EMPTY;
my $language = $EMPTY;

my $actionname = $EMPTY;
my $actiondesc = $EMPTY;

my $mapid      = -1;
my $mapname    = $EMPTY;
my $mapnameold = $EMPTY;
my $osmurl     = $EMPTY;
my $mapcode    = $EMPTY;
my $maplang    = $EMPTY;
my $maptype    = $EMPTY;
my $mapparent  = $EMPTY;
my $langdesc   = $EMPTY;
my $maptypfile = "freizeit.TYP";

my $error   = -1;
my $command = $EMPTY;

# get the command line parameters
GetOptions ( 'h|?' => \$help, 'o' => \$optional, 'ram=s' => \$ram, 'cores=s' => \$cores, 'ele=s' => \$ele, 'typfile=s' => \$typfile, 'language=s' => \$language );

# Show help if wished
if ( ( $help ) || ( $optional ) ) {
  show_help ();
  exit(0);
}

# Definitely not enough arguments
if ( ( $#ARGV + 1 ) < 2 ) {
  printf { *STDOUT } ( "ERROR:\n  Not enough Arguments\n\n\n" );
  show_usage ();
  exit(1);
}

if ( $ram ne $EMPTY ) {
  $javaheapsize = $ram;
}

# Beispiel: --max-jobs=4
if ( lc ( $cores ) eq 'max' ) {
  $max_jobs    = ' --max-jobs';
  $max_threads = ' --max-threads';
}
else {
  $max_jobs    = ' --max-jobs=' . $cores;
  $max_threads = ' --max-threads=' . $cores;
}

$actionname = $ARGV[ 0 ];
$mapid      = $ARGV[ 1 ];
$mapcode    = $ARGV[ 1 ];
$mapname    = $ARGV[ 1 ];

# Checking Arguments for valid actions
$error = 1;
for my $actiondata ( @actions ) {
  if ( @$actiondata[ $ACTIONNAME ] eq $actionname ) {
    $actionname = @$actiondata[ $ACTIONNAME ];
    $actiondesc = @$actiondata[ $ACTIONDESC ];
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

# Checking arguments for valid maps
$error = 1;
for my $mapdata ( @maps ) {
  if ( ( @$mapdata[ $MAPNAME ] eq $mapname ) || ( @$mapdata[ $MAPID ] eq $mapid ) || ( @$mapdata[ $MAPCODE ] eq $mapcode ) ) {
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
  printf { *STDOUT } ( "ERROR:\n  Map '" . $mapid . "' not valid (invalid ID, code or name).\n\n\n" );
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
#if ( (-e "$BASEPATH/TYP/" . basename("$maptypfile",".TYP") . ".txt" ) || (-e "$BASEPATH/TYP/" . basename("$maptypfile",".typ") . ".txt" ) ){
if ( -e "$BASEPATH/TYP/" . basename("$maptypfile", (".TYP", ".typ" ) ) . ".txt" ) {
      $error    = 0;
      $maptypfile = basename("$maptypfile", (".TYP", ".typ" ) ) ;
}
if ( $error ) {
  printf { *STDOUT } ( "ERROR:\n  TYP file '" . $maptypfile . "' not found.\n\n\n" );
  show_usage ();
  exit(1);
}

# Entwicklungsumgebung auf Konsistenz pruefen.
my $directory = 'install';
if ( !( -e $directory ) ) {
  mkdir ( $directory );
  printf { *STDOUT } ( "Directory %s created.\n", $directory );
}

$directory = 'work';
if ( !( -e $directory ) ) {
  mkdir ( $directory );
  printf { *STDOUT } ( "Directory %s created.\n\n", $directory );
}

printf { *STDOUT } ( "Action = %s\n", $actiondesc );
printf { *STDOUT } ( "Map  = %s (%s)\n", $mapname, $mapid );

# Create the WORKDIR and the INSTALLDIR variables, used at a lot of places
my $WORKDIR    = '';
my $INSTALLDIR = '';

# If this map is a downloaded extract from which we extract further regions
if ( $maptype == 1 ) {
  # no language code added as this map itself isn't thought to be built up to the end
  $WORKDIR    = "$BASEPATH/work/$mapname";
  $INSTALLDIR = "$BASEPATH/install/$mapname";
}
else {
  # Normal map, add language code to WORKDIR and INSTALLDIR
  $WORKDIR    = "$BASEPATH/work/$mapname" . "_$maplang";
  $INSTALLDIR = "$BASEPATH/install/$mapname" . "_$maplang";
}

# Execute the choosen action
if ( $actionname eq 'create' ) {
  create_dirs ();
}
elsif ( $actionname eq 'fetch_osm' ) {
  fetch_osmdata ();
}
elsif ( $actionname eq 'fetch_ele' ) {
  fetch_eledata ();
}
elsif ( $actionname eq 'join' ) {
  join_mapdata ();
}
elsif ( $actionname eq 'split' ) {
  split_mapdata ();
}
elsif ( $actionname eq 'build' ) {
#  create_cfgfile           ();
#  create_typfile           ();
#  create_styletranslations ();
#  preprocess_styles        ();
#  build_map                ();
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
  create_typfile      ();
  create_nsis_nsifile ();
  create_nsis_exefile ();
}
elsif ( $actionname eq 'gmapsupp' ) {
  create_typfile      ();
  create_gmapsuppfile ();
}
elsif ( $actionname eq 'imagedir' ) {
  create_typfile         ();
  create_image_directory ();
}
elsif ( $actionname eq 'cfg' ) {
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
elsif ( $actionname eq 'nsicfg' ) {
  create_nsis_nsifile ();
}
elsif ( $actionname eq 'nsiexe' ) {
  create_nsis_exefile ();
}
elsif ( $actionname eq 'gmap2' ) {
  create_typfile   ();
  create_gmap2file ();
}
elsif ( $actionname eq 'bim' ) {
  create_dirs              ();
  fetch_osmdata            ();
  fetch_eledata            ();
  join_mapdata             ();
  split_mapdata            ();
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
  create_gmapfile        ();
  create_nsis_nsifile    ();
  create_nsis_exefile    ();
  create_gmapsuppfile    ();
  create_image_directory ();
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
elsif ( $actionname eq 'checkurl' ) {
  check_downloadurls ();
}

exit ( 0 );


# -----------------------------------------
# Systembefehl ausfuehren
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
    printf { *STDERR } ( "Warning: system($command) failed: $?\n" );

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
# Verzeichnisse mit allen enthaltenen Daten loeschen und neu anlegen.
# -----------------------------------------
sub create_dirs {

  printf { *STDOUT } ( "\n" );

  # Verzeichnisstrukturen loeschen
  rmtree ( "$WORKDIR",    0, 1 );
  rmtree ( "$INSTALLDIR", 0, 1 );

  sleep 1;

  # Verzeichnisstrukturen neu anlegen
  mkpath ( "$WORKDIR" );
  mkpath ( "$INSTALLDIR" );

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
    $command = "$BASEPATH/windows/wget/wget.exe -q --spider ";
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
  }

  # run through the complete maps array
  for my $mapdata ( @maps ) {
	
	# Jump to next it's not a real map
	if ( ( @$mapdata[ $MAPID ] == -1 ) || ( @$mapdata[ $OSMURL ] eq "NA" ) ) {
		next;
    }

    # Real map, print out a header per map
    print "\n" . @$mapdata[ $MAPNAME ] . "\n";
    print "---------------------------------------------------\n";

    # Check the MapURL
    $returnvalue = system( $command . @$mapdata[ $OSMURL ]);
    if ( $returnvalue != 0 ) {
		print "FAIL: ";
	}
	else {
		print "OK:   ";
    }
    print @$mapdata[ $OSMURL ] ."\n";
    
    # Check the ElevationData 10m
    $returnvalue = system( $command . "$elevationbaseurl{ele10}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" );
    if ( $returnvalue != 0 ) {
		print "FAIL: ";
	}
	else {
		print "OK:   ";
    }
    print "$elevationbaseurl{ele10}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" . "\n";  

    # Check the ElevationData 25m
    $returnvalue = system( $command . "$elevationbaseurl{ele25}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" );
    if ( $returnvalue != 0 ) {
		print "FAIL: ";
	}
	else {
		print "OK:   ";
    }
    print "$elevationbaseurl{ele25}/Hoehendaten_" . @$mapdata[ $MAPNAME ] . ".osm.pbf" . "\n";      
	  
  }
	
}

# -----------------------------------------
# OSM-Kartendaten aus Internet laden.
# -----------------------------------------
sub fetch_osmdata {

  my $filename = "$WORKDIR/Kartendaten_$mapname.osm.pbf";

  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $command = "curl --location --url \"$osmurl\" --output \"$filename\"";
    process_command ( $command );
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    chdir "$BASEPATH/windows/wget";
    $command = "wget.exe --output-document=\"$filename\" \"$osmurl\"";
    process_command ( $command );
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
  }

  # auf gültige osm.pbf-Datei prüfen
  if ( !check_osmpbf ( $filename ) ) {
    printf { *STDERR } ( "\nError: File <$filename> is not a valid osm.pbf file.\n" );
    printf { *STDERR } ( "Please check this file concerning error hints (eg. communications errors).\n" );
  }

  return;
}


# -----------------------------------------
# Höhendaten (elevations, contours) aus Internet laden.
# -----------------------------------------
sub fetch_eledata {

  my $filename = "$WORKDIR/Hoehendaten_$mapname.osm.pbf";

  # Download-URL
  my $eleurl = '';
  if ( $ele == 10 ) {
    $eleurl = "$elevationbaseurl{ele10}/Hoehendaten_$mapname.osm.pbf";
  }
  else {
    # Default = 25 Meter
    $eleurl = "$elevationbaseurl{ele25}/Hoehendaten_$mapname.osm.pbf";
  }

  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $command = "curl --location --url \"$eleurl\" --output \"$filename\"";
    process_command ( $command );
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    chdir "$BASEPATH/windows/wget";
    $command = "wget.exe --output-document=\"$filename\" \"$eleurl\"";
    process_command ( $command );
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
  }

  # auf gültige osm.pbf-Datei prüfen
  if ( !check_osmpbf ( $filename ) ) {
    printf { *STDERR } ( "\nError: File <$filename> is not a valid osm.pbf file.\n" );
    printf { *STDERR } ( "Please check this file concerning error hints (eg. communications errors).\n" );
  }

  return;
}


# -----------------------------------------
# OSM- und Höhendaten zusammenführen.
# -----------------------------------------
sub join_mapdata {

  # Verzeichnis wechseln
  chdir "$WORKDIR";

  my $filename_kartendaten  = "$WORKDIR/Kartendaten_$mapname.osm.pbf";
  my $available_kartendaten = 0;

  if ( -e $filename_kartendaten ) {
    # auf gültige osm.pbf-Datei prüfen
    if ( check_osmpbf ( $filename_kartendaten ) ) {
      $available_kartendaten = 1;
    }
  }

  my $filename_hoehendaten  = "$WORKDIR/Hoehendaten_$mapname.osm.pbf";
  my $available_hoehendaten = 0;

  if ( -e $filename_hoehendaten ) {
    # auf gültige osm.pbf-Datei prüfen
    if ( check_osmpbf ( $filename_hoehendaten ) ) {
      $available_hoehendaten = 1;
    }
  }

  my $filename_ergebnisdaten = "$WORKDIR/$mapname.osm.pbf";

  if ( $available_kartendaten && $available_hoehendaten ) {
    # Karten- und Höhendaten vorhanden
    printf { *STDERR } ( "\nJoining map and elevation data ...\n" );

    # Java-Optionen in Osmosis-Aufruf einbringen
    my $javacmd_options = '-Xmx' . $javaheapsize . 'M';
    $ENV{ JAVACMD_OPTIONS } = $javacmd_options;

    # osmosis-Aufrufparameter
    my $osmosis_parameter = 
        " --read-pbf $filename_kartendaten" 
      . " --read-pbf $filename_hoehendaten" 
      . " --merge" 
      . " --write-pbf $filename_ergebnisdaten" 
      . " omitmetadata=true";

    if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
      # OS X, Linux, FreeBSD, OpenBSD
      $command = "sh $BASEPATH/tools/osmosis/bin/osmosis $osmosis_parameter";
      process_command ( $command );
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
      # Windows
      $command = "$BASEPATH/tools/osmosis/bin/osmosis.bat $osmosis_parameter";
      process_command ( $command );
    }
    else {
      printf { *STDERR } ( "\nFehler: Betriebssystem $OSNAME nicht unterstuetzt.\n" );
    }
  }
  elsif ( $available_kartendaten ) {
    # nur Kartendaten vorhanden
    printf { *STDERR } ( "\nWarning: Elevation data file <$filename_hoehendaten> not found.\n" );
    printf { *STDERR } ( "\nCopying map data ...\n" );

    # Kartendaten kopieren
    copy ( $filename_kartendaten, $filename_ergebnisdaten ) or die ( "copy() failed: $!\n" );
  }
  else {
    # weder Karten- noch Hoehendaten vorhanden
    printf { *STDERR } ( "\nError: Map data file <$filename_kartendaten> not found.\n" );
  }

  return;
}


# -----------------------------------------
# Kartendaten splitten.
# -----------------------------------------
sub split_mapdata {

  my $filename_ergebnisdaten = "$WORKDIR/$mapname.osm.pbf";

  if ( -e $filename_ergebnisdaten ) {
    # auf gültige osm.pbf-Datei prüfen
    if ( !check_osmpbf ( $filename_ergebnisdaten ) ) {
      printf { *STDERR } ( "\nError: Resulting data file <$filename_ergebnisdaten> is not a valid osm.pbf file.\n" );
      return ( 1 );
    }
  }
  else {
    printf { *STDERR } ( "\nError: Resulting data file <$filename_ergebnisdaten> does not exists.\n" );
    return ( 1 );
  }

  # OSM-Kartendaten splitten
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

  return;
}


# -----------------------------------------
# Kartenindividuelles CFG-File erzeugen.
# - Note that option order is significant.
# - An option only applies to subsequent input files.
# -----------------------------------------
sub create_cfgfile {

  my $filename_source       = "$WORKDIR/$mapname.osm.pbf";
  my $filename_source_mtime = ( stat ( $filename_source ) )[ 9 ];
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime ( $filename_source_mtime );

  printf { *STDOUT } ( "\n" );

  my $filename = "$WORKDIR/$mapname.cfg";
  printf { *STDOUT } ( "Creating $filename ...\n" );
  open ( my $fh, '+>', $filename ) or die ( "Can't open $filename: $OS_ERROR\n" );

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
      . "description=\"%s (Release %d.%d)\"\n", 
    $mapname, 
    ( $year - 100 ), 
    ( $mon + 1 ) 
  );

  printf { $fh } ( "\n# Label options:\n" );
  printf { $fh } ( "# -------------\n" );

  printf { $fh } 
    (   "\n" 
      . "# --latin1\n" 
      . "#   This is equivalent to --code-page=1252.\n" 
      . "latin1\n" );

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
      . "style-file=$WORKDIR\n" );

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
      ( ( ( $year - 100 ) * 100 ) + ( $mon + 1 ) ) );

  printf { $fh } (
    "\n"
      . "# --series-name\n"
      . "#   This name will be displayed in MapSource in the map selection\n"
      . "#   drop-down. The default is \"OSM map\".\n"
      . "series-name=%s\n",
      $mapname );

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
      . "# --copyright-message=note\n"
      . "#   Specify a copyright message for files that do not contain one.\n"
      . "copyright-message = \"Map: FZK project; Data: OSM contributors, U.S.G.S, de Ferranti\"\n" );

  printf { $fh }
    (   "\n"
      . "# --license-file=file\n"
      . "#   Specify a file which content will be added as license. Every\n"
      . "#   line is one entry. All entrys of all maps will be merged, unified\n"
      . "#   and shown in random order.\n"
      . "license-file=license.txt\n" );

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
      . "remove-short-arcs=3\n" );

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

  printf { $fh }
    (   "\n" 
      . "# --verbose\n" 
      . "#   Makes some operations more verbose. Mostly used with --list-styles.\n" 
      . "verbose\n" );

  printf { $fh }
    (   "\n" 
      . "# --x-housenumbers\n"
      . "#   Housenumbers that are tagged with addr:housenumber and addr:street are now\n"
      . "#   applied. It can be enabled with the undocumented parameter --x-housenumbers.\n"
      . "#   It's not yet an official parameter because it handles only a small\n"
      . "# subset of housenumbers.\n"
      . "x-housenumbers\n" );

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
      printf { $fh } ( "%s: %d.%d%s", $identifier, ( $year - 100 ), ( $mon + 1 ), $rest );
    }

    if ( $identifier eq 'input-file' ) {
      printf { $fh } ( "%s\n", $line );
    }
  }

  # -- hier keine Optionen anfügen --

  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );

  return;
}

# -----------------------------------------
# Ableitung des 'typ-translations' file mit allen sprachspezifischen Strings
# -----------------------------------------
sub create_typtranslations {

  # Create some output (just to know where we are)
  print "\nCreating complete source txt files for the TYP files\n"
      . "  (containing all needed language strings)\n\n";
	
  # Verzeichnisstrukturen neu anlegen (falls noch nicht vorhanden)
  # (Shouldn't be necessary anymore)
#  mkpath ( "$WORKDIR/TYP" );


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
  my $langcode    = $maplang;

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
    if ( ( $tmp ne $langcode ) && ( $stringindex le 4 ) ) {
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

    # Get the line
    $inputline = $_;

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
      $inputline =~ /^Type=(0x[0-9A-F]{2,5})/i;
      $thisobjecttype = $1;
      if ( $thisobjectform eq "point" ) {
        $inputline = <IN>;
        $inputline =~ /^SubType=(0x[0-9A-F]{2,5})/i;
        $thisobjectsubtype = $1;
      }

      # Create the Object ID
      $thisobjectid = "$thisobjectform" . "_" . "$thisobjecttype" . "_" . "$thisobjectsubtype";

      # Get strings
      while ( <IN> ) {
        last if /^\[end\]/;    # Object finished, get on
        $inputline = $_;
        # Check for strings
        if ( $inputline =~ /^String[0-4]*=(0x[0-9A-F]{2}),(.*)$/i ) {
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
#    $outputfile = "$WORKDIR/TYP/$actualfile";
    $outputfile = "$WORKDIR/$actualfile";

    open IN, "< $inputfile" or die "Can't open $inputfile : $!";
    #  open OUT, ">:encoding(UTF-8)","$outputfile" or die "Can't open $outputfile : $!";
    open OUT, ">:", "$outputfile" or die "Can't open $outputfile : $!";

    # Read through the inputfile
    while ( <IN> ) {

      # Get the line
      $inputline = $_;

      # empty the temporary variables
      $thisobjectform        = '';
      $thisobjecttype        = '';
      $thisobjectsubtype     = '';
      $thisobjectid          = '';
      $thisobjectstringsdone = 0;
      %thisobjectstrings     = ();

      if ( $inputline =~ /^\[_(line|polygon|point)\]$/ ) {
        print OUT $inputline;

        $thisobjectform = $1;

        # read nextline
        $inputline = <IN>;
        print OUT $inputline;

        $inputline =~ /^Type=(0x[0-9A-F]{2,5})/i;
        $thisobjecttype = $1;
        if ( $thisobjectform eq "point" ) {
          $inputline = <IN>;
          print OUT $inputline;
          $inputline =~ /^SubType=(0x[0-9A-F]{2,5})/i;
          $thisobjectsubtype = $1;
        }

        # Create the Object ID
        $thisobjectid = "$thisobjectform" . "_" . "$thisobjecttype" . "_" . "$thisobjectsubtype";

        # Get strings
        while ( <IN> ) {
          $inputline = $_;

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
                  print OUT $inputline;
                  last;
                }
              }
            }
          }
          elsif ( $inputline =~ /^\[end\]/ ) {
            print OUT $inputline;
            last;
          }
          else {
            print OUT $inputline;
          }
        }
      }
      else {
        print OUT $inputline;
      }
    }

    close IN;
    close OUT;

  }
}


# -----------------------------------------
# Kompilieren der TYP files aus txt source files
# -----------------------------------------
sub compile_typfiles {
	

  # Create some output (just to know where we are)
  print "\nCompiling source txt files into binary TYP files:\n\n";
	
  # Verzeichnisstrukturen neu anlegen (falls noch nicht vorhanden)
  # (shouldn't be needed anymore
#  mkpath ( "$WORKDIR/TYP" );

  # Verzeichnis wechseln
#  chdir "$WORKDIR/TYP";
  chdir "$BASEPATH/TYP";
  my @typfilelist = glob "*.txt" ;
  chdir "$WORKDIR";
  
  # Run through the existing textfiles
  for my $thistypfile ( @typfilelist ) {

    # run that file through the compiler
    $command = "java -Xmx" . $javaheapsize . "M" . " -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs --code-page=1252 --product-id=1 --family-id=$mapid $thistypfile";
    process_command ( $command );

    #Rename .typ to .TYP
    move(basename("$thistypfile", ".txt") . ".typ" , basename("$thistypfile", ".txt" ) . ".TYP" );
  }

  # temporär erzeugte Dateien löschen
  unlink ( "osmmap.tdb" );
  unlink ( "osmmap.img" );
  
  # 

  return;
}

# -----------------------------------------
# Kartenindividuelles TYP-File aus dem Master-TYP-File ableiten.
# -----------------------------------------
sub create_typfile {

  # Verzeichnis wechseln
#  chdir "$BASEPATH/TYP";
#  chdir "$WORKDIR/TYP";
  chdir "$WORKDIR";

  # TYP-File kopieren
  copy ( "$maptypfile.TYP", "$WORKDIR/$mapid.TYP" ) or die ( "copy() of $maptypfile.TYP failed: $!\n" );

  # Family-ID anpassen
  # Not needed anymore as we're creating them already with the correct IDs
#  $command = "perl set-typ.pl $mapid 1 $WORKDIR/$mapid.TYP";
#  process_command ( $command );

  return;
}


# -----------------------------------------
# Ableitung des 'style-translations' file mit allen sprachspezifischen Strings
# -----------------------------------------
sub create_styletranslations {

  # Set some Variables
  my $inputfile  = "$BASEPATH/translations/style-translations-master";
  my $outputfile = "$WORKDIR/style-translations";
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
# Vorverarbeitung der Style-Files.
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

  # Verzeichnis wechseln
#  chdir "$BASEPATH/style";

  # copying the files from the style directory into the work directory
  for my $stylefile ( glob "$BASEPATH/style/*-master" ) {
    copy ( $stylefile, $WORKDIR ) or die ( "copy() of style files failed: $!\n" );
  }

  # Go to the Workdir
  chdir "$WORKDIR";


  # Preprozessor-Optionen zusammenbauen (alle Angaben hinter dem Kartennamen)
  # $ARGV[ 0 ]                = Aktion;
  # $ARGV[ 1 ]                = Karte oder ID;
  # $ARGV[ 2 ] ... $ARGV[ N ] = Preprozessor-Optionen
  my $ppp_optionen = '';
  foreach my $argnum ( 2 .. $#ARGV ) {
    $ppp_optionen .= "-$ARGV[$argnum] ";
  }
  # Add the Preprozessor Option for the language
  $ppp_optionen .= "\U-D$maplang";

  # indexsearch verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl indexsearch-master indexsearch -x $ppp_optionen";
  process_command ( $command );

  # info verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl info-master info -x $ppp_optionen";
  process_command ( $command );

  # options verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl options-master options -x $ppp_optionen";
  process_command ( $command );

  # version verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl version-master version -x $ppp_optionen";
  process_command ( $command );

  # polgons verarbeiten
  $command = "perl $BASEPATH/tools/ppp/ppp.pl polygons-master polygons -x $ppp_optionen";
  process_command ( $command );

  # lines verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl lines-master lines -x $ppp_optionen";
  process_command ( $command );

  # points verarbeiten
  $command = "perl  $BASEPATH/tools/ppp/ppp.pl points-master points -x $ppp_optionen";
  process_command ( $command );

  return;
}


# -----------------------------------------
# Karte erzeugen.
# -----------------------------------------
sub build_map {

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  # Lizenz-File kopieren
  copy ( "$BASEPATH/license.txt", "license.txt" ) or die ( "copy() failed: $!\n" );

  # OSM-Daten compilieren (-Dlog.config=logging.properties)
  $command = "java -Xmx" . $javaheapsize . "M" . " -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs -c $mapname.cfg";
  process_command ( $command );

  return;
}


# -----------------------------------------
# Garmin-Map-File für BaseCamp erzeugen.
# Tool : gmapi-builder.py
# OS   : OS X
# -----------------------------------------
sub create_gmap2file {

  if ( $OSNAME ne 'darwin' ) {
    printf { *STDERR } ( "\nError: Function only on OS X possible.\n" );
    return;
  }

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

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
    . " *.img";
  process_command ( $command );

  return;
}


# -----------------------------------------
# nsi-Datei für den NSIS-Compiler (Windows) erzeugen (zum Erstellen einer Installationsdatei für Windows).
# -----------------------------------------
sub create_nsis_nsifile {

  my $filename = $mapname . ".nsi";
  printf { *STDOUT } ( "\nCreating $filename ...\n" );

  # Verzeichnis wechseln
#  chdir "$WORKDIR/TYP";
  chdir "$WORKDIR";

#  my @typfiles = ( "$mapid.TYP" , glob ( "*.TYP" ) );
  my @typfiles = ( glob ( "*.TYP" ) );
  for my $thistypfile ( @typfiles ) {
    printf { *STDOUT } ( "TYP-File = $thistypfile\n" );
  }

  # Verzeichnis wechseln
#  chdir "$WORKDIR";

  #my $familyID = substr ( $typfiles[ 0 ], 0, 4 );
  my $familyID = $mapid;
  printf { *STDOUT } ( "Family-ID = $familyID\n" );

  my @imgfiles = glob ( $familyID . "*.img" );
  for my $imgfile ( @imgfiles ) {
    printf { *STDOUT } ( "IMG-File = $imgfile\n" );
  }

  # Beispiel: 11.07 = Jahr.Monat
  my $filename_source       = "$WORKDIR/" . $mapname . ".osm.pbf";
  my $filename_source_mtime = ( stat ( $filename_source ) )[ 9 ];
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime ( $filename_source_mtime );
  printf { *STDOUT } ( "Ausgabe %d.%02d\n", ( $year - 100 ), ( $mon + 1 ) );

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
  printf { $fh } ( "!define KARTEN_AUSGABE \"(Ausgabe %d.%02d)\"\n", ( $year - 100 ), ( $mon + 1 ) );
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
  printf { $fh } ( "; Installer Pages\n" );
  printf { $fh } ( "; ---------------\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh }
    (
    "!define MUI_WELCOMEPAGE_TEXT \"Dieser Assistent wird Sie durch die Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor der Installation muss das Programm BaseCamp geschlossen werden damit Kartendateien ersetzt werden koennen.\$\\n\$\\nKlicken Sie auf Weiter um mit der Installation zu beginnen.\"\n"
    );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"Installation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh }
    (
    "!define MUI_FINISHPAGE_TEXT \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich auf Ihrem Computer installiert.\$\\n\$\\nViel Erfolg und Freude bei der Nutzung der Karte.\$\\n\$\\nUm die Qualitaet dieser Karte zu sichern und zu verbessern ist auch Ihr Feedback (z.B. zu Defekten oder Verbesserungen) hilfreich. An dieser Stelle schon einmal Danke hierfuer.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Installation abzuschliessen.\"\n"
    );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_WELCOMEFINISHPAGE_BITMAP Install.bmp\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_WELCOME\n" );
  printf { $fh } ( "!insertmacro MUI_PAGE_LICENSE lizenz_haftung_erstellung.txt\n" );
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
  printf { $fh } ( "!define MUI_WELCOMEPAGE_TITLE \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE}\"\n" );
  printf { $fh }
    (
    "!define MUI_WELCOMEPAGE_TEXT \"Dieser Assistent wird Sie durch die Deistallation der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} begleiten.\$\\n\$\\nVor dem Entfernen muss das Programm BaseCamp geschlossen werden damit Kartendateien geloescht werden koennen.\$\\n\$\\nKlicken Sie auf Weiter um mit der Deinstallation zu beginnen.\"\n"
    );
  printf { $fh } ( "\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE_3LINES\n" );
  printf { $fh } ( "!define MUI_FINISHPAGE_TITLE \"Entfernen der \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} abgeschlossen\"\n" );
  printf { $fh }
    (
    "!define MUI_FINISHPAGE_TEXT \"Die \${KARTEN_BESCHREIBUNG} \${KARTEN_AUSGABE} wurde erfolgreich von Ihrem Computer entfernt.\$\\n\$\\nKlicken Sie auf Fertig stellen um den Assistenten zu beenden und die Deinstallation abzuschliessen.\"\n"
    );
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
  printf { $fh } ( "!insertmacro MUI_LANGUAGE \"German\"\n" );
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
  printf { $fh } ( "  ; Uninstall before Installing (actual mapname)\n" );
  printf { $fh } ( "  ; -------------------------------------------\n" );
  printf { $fh } ( "  ReadRegStr \$R0 HKLM \\\n" );
  printf { $fh } ( "  \"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\${REG_KEY}\" \\\n" );
  printf { $fh } ( "  \"UninstallString\"\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  StrCmp \$R0 \"\" noactualcard\n" );
  printf { $fh } ( "\n" );
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \\\n" );
  printf { $fh }
    (
    "  \"Es ist bereits eine Version der \${KARTEN_BESCHREIBUNG} installiert.\$\\nDiese Version muss zunaechst entfernt werden.\" \\\n"
    );
  printf { $fh } ( "  IDOK uninstactualcard\n" );
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
  printf { $fh } ( "  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \\\n" );
  printf { $fh }
    (
    "  \"Es ist bereits eine Version der \${KARTEN_BESCHREIBUNG} installiert.\$\\n(noch mit altem Namen \${REG_KEY_OLD})\$\\nDiese Version muss zunaechst entfernt werden.\" \\\n"
    );
  printf { $fh } ( "  IDOK uninstoldcard\n" );
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

  printf { $fh } ( "  !addplugindir \"\%s\\windows\\NSIS\\Plugins\"\n", $BASEPATH );

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
# Mit NSIS-Compiler Installer-Executable für Windows erzeugen.
# Tool : makensis.exe
# OS   : Linux, Windows
# -----------------------------------------
sub create_nsis_exefile {

  my $source      = $EMPTY;
  my $destination = $EMPTY;
  my $zipper      = $EMPTY;

  # Prep for creating the Installer: get OS dependent command name for zipper
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    printf { *STDERR } ( "\nError: Function on OS X not possible.\n" );
    return;
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
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
    return;
  }

  # Copy the rest of the TYP files (actually hidden in a TYP subdirectory of the WORKDIR)
  # (shouldn't be necessary anymore)
#  chdir "$WORKDIR/TYP";
#  for my $file ( <*.TYP> ) {
#    printf { *STDOUT } ( "Copying %s\n", $file );
#    copy ( $file, "$WORKDIR" . "/" . $file ) or die ( "copy() $file failed: $!\n" );
#  }  

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  # Create the needed zip file
  $source      = '*.img *.tdb *.mdx *.TYP';
  $destination = $mapname . '_InstallFiles.zip';
  $command     = $zipper . "$destination $source";
  process_command ( $command );

  # Remove the additional TYP files again from workdir, they disturb jmc_cli at the moment
  # (shouldn't be necessary anymore)
#  chdir "$WORKDIR/TYP";
#  for my $file ( <*.TYP> ) {
#    printf { *STDOUT } ( "Removing %s again\n", $file );
#    unlink ( $WORKDIR . "/" . $file );
#  }  
#  chdir "$WORKDIR";


  # Prep for creating the Installer: get OS dependent command name for nsis and zipper
  if ( $OSNAME eq 'darwin' ) {
    # OS X
    printf { *STDERR } ( "\nError: Function on OS X not possible.\n" );
    return;
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/windows/NSIS/makensis.exe $mapname" . ".nsi";
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $command = "makensis $mapname" . ".nsi";
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
    return;
  }

  # in nsis-Verzeichnis wechseln
  chdir "$BASEPATH/nsis";

  # Lizenz und Bitmaps kopieren
  copy ( "lizenz_haftung_erstellung.txt", "$WORKDIR/lizenz_haftung_erstellung.txt" )
    or die ( "copy() failed: $!\n" );
  copy ( "Install.bmp",   "$WORKDIR/Install.bmp" )   or die ( "copy() failed: $!" );
  copy ( "Deinstall.bmp", "$WORKDIR/Deinstall.bmp" ) or die ( "copy() failed: $!" );

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  # Installer-Executable erzeugen (mit NSIS-Compiler)
  process_command ( $command );

  # Installer-Executable ins install-Verzeichnis verschieben
  my $filename = "Install_" . $mapname . "_" . $maplang . ".exe";

  # sleep needed on windows... perl is faster than windows... (Viruschecking ?)
  sleep 30;
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!: move $filename $INSTALLDIR/$filename\n" );

  # Delete the zip file again, not needed anymore
  unlink ( $mapname . "_InstallFiles.zip" );

  return;

}


# -----------------------------------------
# Garmin-Map-File für BaseCamp erzeugen.
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
sub create_gmapfile {

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  # Verzeichnisstruktur loeschen
  rmtree ( "$INSTALLDIR/$mapname.gmap", 0, 1 );

  # Create the config file we use for jmc_cli (v0.7)1
  my $filename = "$WORKDIR/jmc_cli.cfg";
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
  printf { $fh } ( "sourcefolder = $WORKDIR\n" );
  printf { $fh } ( "destfolder = $INSTALLDIR\n" );
  
  printf { $fh } ( "\n# Optional stuff options:\n" );
  printf { $fh } ( "# -----------------------\n" );
  
  # add requiered source and destination directory to the config file
  printf { $fh } ( "basemap = $mapname.img\n" );
  printf { $fh } ( "TYPfile = $mapid.TYP\n" );

  close ( $fh ) or die ( "Can't close $filename: $OS_ERROR\n" );

  printf { *STDOUT } ( "Done\n" );



  # jmc-Aufrufparameter
#  my $jmc_parameter = "-v -src=\"$WORKDIR\" -dest=\"$INSTALLDIR\" -bmap=\"$mapname.img\"";
  my $jmc_parameter = "-v -config=\"$WORKDIR/jmc_cli.cfg\"";

  if ( $OSNAME eq 'darwin' ) {
    # OS X
    $command = "$BASEPATH/tools/jmc/osx/jmc_cli $jmc_parameter";
    process_command ( $command );
  }	
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $command = "$BASEPATH/tools/jmc/windows/jmc_cli.exe $jmc_parameter";
    process_command ( $command );
  }
  elsif ( ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # Linux, FreeBSD (ungetestet), OpenBSD (ungetestet)
    $command = "$BASEPATH/tools/jmc/linux/jmc_cli $jmc_parameter";
    process_command ( $command );
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
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
# gmapsupp-Image für GPS-Gerät erzeugen.
# Vorbedingung: OSM-Daten bereits gebildet
# -----------------------------------------
sub create_gmapsuppfile {

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  my $filename_source       = "$WORKDIR/$mapname.osm.pbf";
  my $filename_source_mtime = ( stat ( $filename_source ) )[ 9 ];
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime ( $filename_source_mtime );

  # Lizenz-File kopieren
  copy ( "$BASEPATH/license.txt", "license.txt" ) or die ( "copy() failed: $!\n" );

  my $mapversion = sprintf ( "%d.%d", ( $year - 100 ), ( $mon + 1 ) );

  # mkgmap-Parameter
  # --description: Anzeige des Kartennamens in BaseCamp
  # --description: alleinige Anzeige des Kartennamens in einigen GPS-Geräten (z.B. 62er)
  # --description: zusätzliche Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --family-name: primäre Anzeige des Kartennamens in einigen GPS-Geräten (z.B. Dakota)
  # --series-name: This name will be displayed in MapSource in the map selection drop-down.
  my $mkgmap_parameter = sprintf (
        "--index --gmapsupp --product-id=1 --family-id=$mapid --family-name=\"$mapname $mapversion\" "
      . "--series-name=\"$mapname $mapversion\" --description=\"$mapname $mapversion\" --overview-mapnumber=%s0000 "
      . "--product-version=%d $mapid*.img $mapid.TYP ",
      $mapid, ( ( ( $year - 100 ) * 100 ) + ( $mon + 1 ) )
  );

  # gmapsupp-Image erzeugen
  $command =
      "java -Xmx"
    . $javaheapsize . "M"
    . " -jar $BASEPATH/tools/mkgmap/mkgmap.jar $max_jobs --license-file=license.txt $mkgmap_parameter";
  process_command ( $command );

  # gmapsupp-Image ins install-Verzeichnis kopieren
  my $filename = "gmapsupp.img";
  move ( $filename, "$INSTALLDIR/$filename" ) or die ( "move() failed: $!\n" );

  # temporär erzeugte Dateien löschen
  unlink ( "osmmap.tdb" );
  unlink ( "osmmap.img" );

  return;
}


# -----------------------------------------
# Einfaches Verzeichnis mit allen Kartendaten erzeugen:
# - *.img, *.tdb, *.mdx, *.TYP
# Karte kann z.B. direkt mit QLandkarte eingelesen werden.
# -----------------------------------------
sub create_image_directory {

  # in work-Verzeichnis wechseln
  chdir "$WORKDIR";

  my $destdir = "$INSTALLDIR/$mapname" . "_Images";

  # (ggf.) existierendes Verzeichnis löschen
  rmtree ( $destdir, { verbose => 1, safe => 1, keep_root => 1 } );

  # Zielverzeichnis anlegen
  mkpath ( $destdir, { verbose => 1 } );

  # img-Dateien kopieren
  for my $file ( <*.img> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }

  # tdb-Datei kopieren
  for my $file ( <*.tdb> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }

  # mdx-Datei kopieren
  for my $file ( <*.mdx> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }

  # TYP-Datei kopieren
  for my $file ( <*.TYP> ) {
    printf { *STDOUT } ( "Copying %s\n", $file );
    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
  }
  
  # Copy the rest of the TYP files (actually hidden in a TYP subdirectory of the WORKDIR)
  # (Shouldn't be necessary anymore)
#  chdir "$WORKDIR/TYP";
#  for my $file ( <*.TYP> ) {
#    printf { *STDOUT } ( "Copying %s\n", $file );
#    copy ( $file, $destdir . "/" . $file ) or die ( "copy() $file failed: $!\n" );
#  }  

  return;
}


# -----------------------------------------
# Alle erzeugten Karten (soweit sinnvoll) zippen.
# -----------------------------------------
sub zip_maps {

  # in installl-Verzeichnis wechseln
  chdir "$INSTALLDIR";

  my $source      = $EMPTY;
  my $destination = $EMPTY;
  my $zipper      = $EMPTY;

  if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
    # OS X, Linux, FreeBSD, OpenBSD
    $zipper = 'zip -r ';
  }
  elsif ( $OSNAME eq 'MSWin32' ) {
    # Windows
    $zipper = $BASEPATH . '/tools/zip/windows/7-Zip/7za.exe a ';
  }
  else {
    printf { *STDERR } ( "\nError: Operating system $OSNAME not supported.\n" );
  }

  # gmap (Beispiel: Freizeitkarte_DEUTSCHLAND.gmap -> Freizeitkarte_DEUTSCHLAND_de.gmap.zip)
  $source      = $mapname . '.gmap';
  $destination = $mapname . '_' . $maplang . '.gmap.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # nsis (Beispiel: Install_Freizeitkarte_DEU_de.exe )
  $source      = "Install_" . $mapname . '_' . $maplang . '.exe';
  $destination = "Install_" . $mapname . '_' . $maplang . '.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }


  # gmapsupp (Beispiel: gmapsupp.img -> DEU_de_gmapsupp.img.zip)
  $source = 'gmapsupp.img';
#  $destination = lc ($mapcode) . '_' . $source . '.zip';
  $destination = $mapcode . '_' . $maplang . '_' . $source . '.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  # imagedir (Beispiel: Freizeitkarte_DEUTSCHLAND_Images -> Freizeitkarte_DEUTSCHLAND_de.Images.zip)
  $source      = $mapname . '_Images';
  $destination = $mapname . '_' . $maplang . '.Images.zip';
  $command     = $zipper . "$destination $source";
  if ( -e $source ) {
    process_command ( $command );
  }

  return;
}

# -----------------------------------------
# Prüfen, ob Datei im osm.pbf-Format vorliegt.
# - nach String 'OSMHeader' im Dateiheader suchen
# - Implementierung möglicherweise unzureichend.
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
# FZK-spezifische Regionen extrahieren.
# -----------------------------------------
sub extract_regions {

  # If this map is a downloaded extract from which we extract further regions, continue
  if ( $maptype == 1 ) {
  
     # Initialisations
     my $source_filename = "$WORKDIR/$mapname.osm.pbf";
     my $osmosis_parameter = "";
     my $osmosis_parameter_bw = "";
     my $max_tee = 10;
     my @childmapnames = ();
     my $osmosis_runs = 0;
     my $actual_tee = 0;
   
     # Check if the source file exists and is a valid osm.pbf file
     if ( -e $source_filename ) {
       if ( !check_osmpbf ( $source_filename ) ) {
         printf { *STDERR } ( "\nError: Resulting data file <$source_filename> is not a valid osm.pbf file.\n" );
         return ( 1 );
       }
     }
     else {
       printf { *STDERR } ( "\nError: Source data file <$source_filename> does not exists.\n" );
       return ( 1 );
     }
   
     # Java-Optionen in Osmosis-Aufruf einbringen
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
             . " --write-pbf file=$WORKDIR/$childmapname.osm.pbf omitmetadata=yes";
		   		   
		}
		
    	# ok, enough together, let's run it (MISSING: IS IT THE LAST ?)
		printf { *STDERR } ( "\nExtracting Freizeitkarte regions ...\n" );

        # osmosis-Aufrufparameter (bei Veränderung auch "tee" anpassen)
        $osmosis_parameter =
            " --read-pbf file=$source_filename"
          . " --tee $actual_tee"
          . " $osmosis_parameter_bw"
          ;

        if ( ( $OSNAME eq 'darwin' ) || ( $OSNAME eq 'linux' ) || ( $OSNAME eq 'freebsd' ) || ( $OSNAME eq 'openbsd' ) ) {
          # OS X, Linux, FreeBSD, OpenBSD
          $command = "sh $BASEPATH/tools/osmosis/bin/osmosis $osmosis_parameter";
          process_command ( $command );
        }
        elsif ( $OSNAME eq 'MSWin32' ) {
          # Windows
          $command = "$BASEPATH/tools/osmosis/bin/osmosis.bat $osmosis_parameter";
          process_command ( $command );
        }
        else {
          printf { *STDERR } ( "\nFehler: Betriebssystem $OSNAME nicht unterstuetzt.\n" );
        }	
 
     }
  }
  else {
     printf { *STDERR } ( "\nERROR: $mapname is not an extract from which we create our own regions \n" );
  }

  return;
}


# -----------------------------------------------
# Bereits passend vorbereitete Kartendaten laden.
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
     printf { *STDERR } ( "\nERROR: $mapname is not a region that needed local extraction.\n" );
  }

  return;
}


# -----------------------------------------
# Show short usage
# -----------------------------------------
sub show_usage {

  # Print the Usage
  printf { *STDOUT } (
    "Usage:\n"
      . "perl $programName [-ram=Value] [-cores=Value] [-ele=Value] [-typfile=\"filename\"] [-language=\"lang\"] <Action> <ID | Code | Map> [PPO] ... [PPO]\n\n"
      . "  or for getting help:\n"
      . "  perl $programName -? | -h | -o\n"
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
#    "Usage:\n"
#      . "perl $programName [-ram=Value] [-cores=Value] [-ele=Value] [-typfile=\"filename\"] [-language=\"lang\"] <Action> <ID | Code | Map> [PPO] ... [PPO]\n\n"
#      . "Examples:\n"
      "Examples:\n"
      . "perl $programName                              build     Freizeitkarte_Hamburg\n"
      . "perl $programName  -ram=1536    -cores=2       build     Freizeitkarte_Hamburg\n"
      . "perl $programName  -ram=6000                   build     5815\n"
      . "perl $programName  -ram=6000    -cores=max     build     5815\n"
      . "perl $programName  -ram=6000    -cores=max     build     Freizeitkarte_Oesterreich  DT36ROUTING\n\n"
      . "Options:\n"
      . "-ram      = javaheapsize in MB (join, split, build) (default = %d)\n"
      . "-cores    = max. number of CPU cores (build) (1, 2, ..., max; default = %d)\n"
      . "-ele      = equidistance of elevation lines (fetch_ele) (10, 25; default = 25)\n"
      . "-typfile  = filename of a valid typfile to be used (build, gmap, nsis, gmapsupp, imagedir, typ) (default = freizeit.TYP)\n"
      . "-language = overwrite the default language of a map (en=english, de=german);\n"
      . "            if you build a map for another language than the map's default language,\n"
      . "            this option needs to be set for all subcommands, else it swaps back to the default language and possibly fails.\n"
      . "PPO       = preprocessor options (multiple possible)\n\n"
      . "Arguments:\n"
      . "Action    = Action to be processed\n"
      . "ID        = ID of the to processed map\n"
      . "Code      = Code of the to processed map\n"
      . "Map       = Name of the to be processed map\n\n",
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
      # alle Länder und Regionen
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
