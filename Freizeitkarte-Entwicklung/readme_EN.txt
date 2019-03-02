Freizeitkarte-OSM.de - Development Environment
Readme_EN.txt - 26.09.2013 - Klaus Tockloth translated by butterscotchmuffin

This development environment is executable with OS X, Windows & Linux
The root directory, built when the development environment is unpacked from the archive, will be named:
   Freizeitkarte-Entwicklung

This name can be changed to your needs, unless its given name does not contain any space characters.
Names of subdirectories must not be changed.

The entire development environment can as well be stored on an external device and executed from there. 

The main utility "mt.pl" (MapTool) is placed straight in the root directory and has to be executed from here. 
Pre-conditions:
- Perl (version 5.10 or later) has to be present on the OS
- Java (version 7 or later) has to be present on the OS
- computer needs at least 2GB RAM
 
Terminal:
- the procedures of creating a map are carried out using a terminal window
- each input command has to be executed one by one 
  alternatively you can create your own batch file


Executing "perl mt.pl" (MapTool) without any parameters, will lead to a minimum help output.
An extensive help output is produced by "perl mt.pl -?" 


Minimum commands to be executed for creating a leisure activity map (used example: Freizeitkarte_LUX)
Change first to the root directory of the development environment:

  cd Freizeitkarte-Entwicklung     (or similar)

For completing the development environment additonal boundary files (around 450 MB) need to be 
downloaded and incorporated once (only the first time you use the development environment). 
For this you have to issue the command:

1. perl mt.pl bootstrap

Now you can build the map

1. perl mt.pl create Freizeitkarte_LUX
2. perl mt.pl fetch_osm Freizeitkarte_LUX
   perl mt.pl fetch_ele Freizeitkarte_LUX
3. perl mt.pl join Freizeitkarte_LUX
4. perl mt.pl split Freizeitkarte_LUX
5. perl mt.pl build Freizeitkarte_LUX
6. according to the target use of the map:
   - Creating a gmap-file to be installed at OS X ("Garmin MapManager")
     perl mt.pl gmap Freizeitkarte_LUX
   - Creating a Windows-Installer
     perl mt.pl nsis Freizeitkarte_LUX
   - Creating a gmapsupp-image-file for Garmin-GPS
     perl mt.pl gmapsupp Freizeitkarte_LUX

To build special maps like Freizeitkarte_DEU+ additional steps are requried:
- fetch_osm - don't fetch Freizeitkarte_DEU+, but fetch Freizeitkarte_EUROPE
- before fetch_ele run extract_osm Freizeitkarte_DEU+

Additional options:
The styles of the maps contain logical switches, the syntax to activate the is the following:
     perl mt.pl build <map> D<option>
For example:
     perl mt.pl build Freizeitkarte_LUX DKULTURLAND

The following options are allowed:
- WINTERSPORT: Display lines for winter sports (pistes, cross country ski tracks, ...) in map [lines-master]
- T36ROUTING: Allows routing for mountain trails or hike paths of classes T3-T6 with map [lines-master]
- TRIGMARK: Display of trigonometric markers in map [points-master]
- NODRINKINGWATER: Do not display of drinking water spots in map [points-master]
- KULTURLAND: Display of agricultural crop land in map [polygons-master]


   

Remarks:
- your first steps to map development should be carried out with a small map, like e.g. Freizeitkarte_LUX
- the building process for a full map of Germany, using a standard computer with 4GB RAM, will take more than 7 hours
- 64-Bit Linux-systems must have 32-Bit support installed
- for creating a Windows-Installer within Linux, NSIS (Nullsoft Scriptable Install System) must be available on your system




Structure of directories of our development environment

The utility works with the structure described below and is the central component of the development environment.
We distinguish from a basic structure and work directories, which will be created during the process of map creation.


Basic structure:
These directories are automatically created in the root directory when unpacking the archive


Freizeitkarte-Entwicklung/bounds:
Repository for bounds/boundary data, which are needed for indexing (e.g. address-search).
This datafiles will be downloaded when you issue the 'bootstrap' command.

Freizeitkarte-Entwicklung/cities:
Repository of geodata about all cities with more than 15000 inhabitants
Used during the splitting-process to give descriptive names to the resulting tiles

Freizeitkarte-Entwicklung/nsis:
Configuration files of nsis

Freizeitkarte-Entwicklung/poly:
Repository of polygons for special maps (Scandinavia, Alps, BeNeLux etc.)

Freizeitkarte-Entwicklung/sea:
Repository of the european coast-line
Used during build-process for displaying the sea propperly.
This datafiles will be downloaded when you issue the 'bootstrap' command.


Freizeitkarte-Entwicklung/style:
Repository for all data defining the looks of our maps
- polygons
- lines
- points
- ...

Freizeitkarte-Entwicklung/tools:
Repository for all tools needed for map creation
- splitter
- mkgmap
- ...

Freizeitkarte-Entwicklung/tools/TYPViewer/windows:
Repository for "TYPViewer"-Installer.
This TYP-Editor is working solely in an Windows OS surrounding and is not used for creating maps.
Before being used, the TYPViewer has to be installed on your Windows using the "Setup.exe".
TYPViewer can be used with english or frensh navigation only.

Freizeitkarte-Entwicklung/translations:
Repository for translations of used notions in Master-STYLE- or Master-TYP-files
Used corresponding to the language base setting of the target map or 
your selection of the language option with MapTool.

Freizeitkarte-Entwicklung/TYP:
Repository for binary TYP-files which define the design of the target map.
To begin with you will find several Master-TYP-files (freizeit.TYP, contrast.TYP, small.TYP etc.) here.
For other than the default design of a target map, a specific TYP-file (with correct Family-ID) is required.
It will derive from the choosen Master-TYP-file via "set-typ.pl"-utility 
From this it follows that: Autonomous changes of an TYP-file have to be made with all Master-TYP-files applicable

Freizeitkarte-Entwicklung/windows/TYPViewer:
Repository for "TYPViewer"-Installer.
This TYP-Editor is working solely in an Windows OS surrounding 
Before being used, the TYPViewer has to be installed on your Windows using the "Setup.exe".
TYPViewer can be used with english or frensh navigation only


Work directories:
The following directories are created and filled during the process of map generation
They can be deleted in the end, since the presence is tested at the next execution and will be created freshly.
Invoke the command "create mt.pl <" card name ">" e.g. at the beginning of a map creation can also initiate 
the (re)creation of the initial state for these directories


Freizeitkarte-Entwicklung/install:
For each map generated a distinct subdirectory is created within here.
The directory names correspond to the names of the maps generated 

Freizeitkarte-Entwicklung/install/"name of the map":
for all directly installable data
- *.gmap = for OS X (and Windows)
- *.exe = Installer for Windows
- gmapsupp.img = image for (Garmin)GPS device

Freizeitkarte-Entwicklung/work:
For each map generated a distinct subdirectory is created here.
The directory names correspond to the names of the maps generated.

Freizeitkarte-Entwicklung/work/"Kartenname":
Repository and clipboard for all data needed and produced during map generation
Resulting files generated during the build process will be moved into the "install" subdirectories.


