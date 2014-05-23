gmt v0.8.143 24.6.2013  (C) 2011-2013 AP www.gmaptool.eu
---------------------------------------------------------------------------
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) License. To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/legalcode or send a letter to Creative Commons, 171 2nd Street, Suite 300, San Francisco, California, 94105, USA.

The program makes the following operations on map files in Garmin format:
- join several maps into single file.
- split map into files for Mapsource,
- split map into parts,
- write corrections into original files and insert a new unlock code,
- display informations about maps.

The program is not fully tested, please use with caution.

Gmt recognizes the following input files: Garmin maps data *.img, *.trf, *.typ and ASCII files with unlock codes *.unl.

Disclaimer:
The program has been written basing on  documentation available in internet and on the data analysis produced by non-Garmin software.
There is no guarantee that this program will create compatible data with Garmin GPS or software. The program in any way doesnt unlock locked maps, 
the user have to have a valid unlock key to use a locked map. The user is responsible for all the consequences in using this program.

usage:

Join maps (-j):
  gmt -j [-v] [-i] [-a] [-b block] [-c no.no[,ms[,prod]]] [-d] [-f FID[,PID]]
         [-h] [-l|-n] [-m map] [-o output_file] [-q] [-r] [-u code]
         [-x] [-z] file...

	-i - information
	-v - verbose

	-a - use other data
	-b - block size kB
	-c - map version, Mapsource flag, product code in header
	-d - create DEMO map
	-f - Family ID and Product ID
	-h - short header img
	-l - use name BLUCHART.MPS
	-m - mapset name
	-n - use name MAPSOURC.MPS
	-o - output file name
	-q - map without autorouting and DEM data
	-r - remove unlock codes
	-u - new unlock code
	-x - do not create MPS subfile
	-z - convert int NT-like format

Split maps for Mapsource (-S):
  gmt -S [-v] [-i] [-c CodePage] [-f FID[,PID]] [-h] [-m map] [-L]
         [-l] [-n name] [-o path] [-q] [-r] [-t] [-3] file...

	-i - information
	-v - verbose

	-c - CodePage for mapset
	-f - Family ID and Product ID
	-h - short header img
	-L - limit map longitude to 178.5
	-l - limit longitude in preview map to 178.5
	-m - mapset name
	-n - mapset files name
	-o - output path
	-q - add empty DEM
	-r - create TDB for marine map
	-t - create split.lst
	-3 - create TDB version 3, if possible

Split maps (-s):
  gmt -s [-v] [-i] [-h] [-m map] [-o path] [-t] [-x] file.img...

	-i - information
	-v - verbose

	-h - short header img
	-m - mapset name
	-o - output path
	-t - create split.lst
	-x - save TYP files only

Split mapsets by FID(-G):
  gmt -G [-v] [-i] [-h] [-l|-n] [-o path] file.img...

	-i - information
	-v - verbose

	-h - short header img
	-l - use name BLUCHART.MPS
	-n - use name MAPSOURC.MPS
	-o - output path

Split into subfiles (-g):
  gmt -g [-v] [-i] [-o path] [-t] file.img...

	-i - information
	-v - verbose

	-o - output path
	-t - create split.lst

Split into empty maps (-k):
  gmt -k [-v] [-i] [-o path] file.img...

	-i - information
	-v - verbose

	-o - output path

Write changes into oryginal files (-w):
  gmt -w [-i] [-v] [-c no.no[,ms[,prod]]] [-e [+|-]map_id] [-f FID[,PID]] 
         [-h] [-L|-l|-1] [-m map] [-n|-t] [-q t1,t2,t3] [-p priority] [-r name]
         [-u code] [-x] [-y FID[,PID[,CP]]] [-r FID[,PID]] file.img...

	-i - information
	-v - verbose

	-c - map version, mapsource flag, product code in header
	-e - new map ID number
	-f - Family ID and Product ID
	-h - refresh header date
	-L - upper case labels
	-l - lower case labels
	-m - mapset name
	-n - non-transparent map
	-p - map priority
	-q - parameters TRE
	-r - map name
	-t - transparent map
	-u - new unlock code
	-x - repleace TYP file in img file
	-y - correct TYP Family ID, Product ID and CodePage
	-z - change Family ID, Product ID in *.MPS
	-1 - first character upper case in labels

You can provide input file list using option -@ list.txt.

Use as first option -LicenseAcknowledge to remove license message.

Option -E will force English language.
Option -P will force Polish language.

---------------------------------------------------------------------------
Join maps
---------------------------------------------------------------------------

* Join all img from a directory and create a mapset on SD card (drive S:):
	gmt -j -o s:\garmin\gmapsupp.img -m "SD Card" *.img

* Remove old unlock codes and insert new unlock code
	gmt -j -r -o new_map.img -u 12345-12345-12345-12345-12345 map.img

* Add type file to mapset:
	gmt -j -o new_map.img map.img 00123456.typ

* Join single maps into mapset:
	gmt -j -o new_map.img -f 5000 -m "New map" 00000001.img 00000002.img 00000003.img

* Add unlock codes from gmapsupp.unl file:
	gmt -j -o new_map.img gmapsupp.img gmapsupp.unl


---------------------------------------------------------------------------
Split maps
---------------------------------------------------------------------------

* Split mapset with short headers:
	gmt -s -h map.img

* Split mapset into output directory: 
	gmt -s -o C:\test\map map.img


---------------------------------------------------------------------------
Split maps for Mapsource
---------------------------------------------------------------------------

* Split mapset from SD card (drive S:)
	gmt -S s:\gramin\gmapsupp.img

* Split mapset into a directory:
	gmt -S -o c:\test\map gmapprom.img 

* Split mapset with given FID and map name:
	gmt -S -f 5000,1 -m "New map name" map.img

* Create new TDB for a mapset already attached to Mapsource:
	gmt -S -f 200,1 -m "map name" 0*.img


---------------------------------------------------------------------------
Write changes into map
---------------------------------------------------------------------------

* Set drawpriority for all maps in a mapset:
	gmt -w -p 20 gmapsupp.img

* Set transparency for maps with FID 200:
	gmt -w -t -f 200 gmapsupp.img

* Insert unlock code:
	gmt -w -u 12345-12345-12345-12345-12345 gmapsupp.img

* Renumber all map ID starting from 200000:
	gmt -w -e 200000 map.img

Attention: option -e is experimental. It is designed to work with unlocked maps compiled with cgpsmapper.
 Map ID is saved in diferent files of mapset, modifying ID in img can make mapset unusable in Mapsource or GPS.

---------------------------------------------------------------------------
Map management with gmt
---------------------------------------------------------------------------

1. For each map in Mapsource create full map image for GPS. It can be written to a flash card reader or GPS. 
Copy file gmpasupp.img from flash/GPS back to PC and rename it to something meaningful, for example CNEv9.img or TopoGB.img.

2. Copy preinstalled maps from your gps. This can be gmapprom.img or gmapsupp.img. Rename it to something meaningful.

3. When you want to install maps to GPS simply choose img files from your collection on PC, move to 
an empty directory and execute command like this:
	gmt -jo f:\garmin\gmapsupp.img *.img

where f: is the drive letter of your GPS internal memory. This way it will go much faster than creating a big mapset in Mapsource.

4. When you get an upgrade for any of your maps, create new img for this map only and replace it in your img collection.


---------------------------------------------------------------------------
How to make your map form gmapsupp.img visible in Mapsource
---------------------------------------------------------------------------

This is not a perfect solution but it works. Somehow :-)

You need some tools to get the work done. Look for cgpsmapper free version and MapSetToolKit:
http://cgpsmapper.com/buy.htm
http://cypherman1.googlepages.com/

Unpack and install all these tools. Cgpsmapper and gmt are command line programs, you need to start them from command 
line window or from any Norton Commander clone like Total Commander.

I assume that you have Mapsource installed and that your GPS with preinstalled maps is recognized by Windows as a removable drive,
 for example as drive I:

Begin with creating an empty directory for your map. Put cgpsmapper and gmt in this directory and make it as current work directory
 for subsequent commands.

Unpack your map with gmt (option is big 'S'):

      >gmt -S I:\garmin\gmapprom.img


You will get several different files in your work directory. These are maps and additional files for Mapsource. You need to compile preview map:

      >cgpsmapper mapset.mp


Now you can use MapSetToolKit. Start it and choose "Install An Existing Mapset". You have to point to tdb file mapset.tdb, preview file 
mapset.img and invent a registry name. Install it and your map should be visible in Mapsource.

Do not try to use MDR file generated by gmt in Mapsource. This will not work!

You have to unlock now the map in Mapsource. Simply input 25-character unlock code from your device. This can be found on papers attached to your GPS,
 on mygarmin.com after registration, in file \garmin\GarminDevice.xml or \garmin\gmapprom.unl or in a file gmaptool00.unl in map directory on your
 PC.

And as usually: no guarantee, Mapsource may crash, use at your own risk and responsibility.
If Mapsource crashes use MapSetToolKit to remove the new map.

Gmt create very simple basic map, just a minimum data to make Mapsource to see the map. This is OK for small area map but not good enough for big maps
 like City Navigators. You can improve preview map adding details form basemap.

First get a basemap. This could be file gmapbmap.img form your GPS, free basemap from Garmin:
http://www8.garmin.com/support/download_details.jsp?id=3645
or World Map from Garmin XT Mobile:
http://www.garmin.ru/GarminMobileXTFull.exe

Next you will need tools, MapEdit:
http://www.geopainting.com/en/

and Personal cGPSmapper 30-day evaluation version:
http://cgpsmapper.com/buy.htm

Split basemap into parts:

      >gmt -s gmapbmap.img

You will get one or more img files with maps. You can view content of this files with MapEdit (press Ctrl-0 if you see empty map).
 For preview choose most detailed map covering the required area.

Open choosen file with MapEdit and do:
File->Map Properties->Levels and check levels number, note this for later use. My map has levels 17, 15, 13, 12, 11. Set zoom 7 for
last level and then correct other levels zoom to get the zoom sequence like 3, 4, 5, 6, 7.
Edit->Select->By Type and select unwanted objects, I recommend selecting all HW-Exits. Close this menu and do Edit->Delete.
File->Save As and save map in polish format .mp.

Open mapset.mp and do:
File->Map Properties->Levels and make levels and zooms exactly like in basemap. Existing levels should be converted into first and 
last level and new empty levels inserted in between.
Edit->Select-All objects then right click on an object and select Modify->Extend All Elements up to Level and set last level index minus 1. 
On my map this is 3.
File->Add and point to basemap saved in mp format. Now your selected objects should be visible on basemap. Use Tools->Trim to select all 
this elements, right click inside selected area and choose Trim outside.
File->Map Properties and check and correct: on Header tab map ID should be 09999999, on cGPSmapper tab POI Index should be on.
File->Save and save your new map in polish format as mapset.mp.

Open mapset.mp in a text editor. This could be very big file, not all editors are capable to deal with it. I'm using Notepad2. Look for text like
 "Region123=" without any name. Correct all empty "=" into "=OTHER".

Run map compilation:

      >cgpsmapper mapset.mp

this can take a lot of time, be prepared to wait an hour or more. As a result you will get new mapset.img that can be added to your mapset
 in Mapsource.

Personal cGPSmapper can make searchable map. When you use preview map with POI and city index, you will be able to search for places in Mapsource.
