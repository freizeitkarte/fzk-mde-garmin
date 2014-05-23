ReplaceTyp.cmd (Windows)
========================
With this tool a user can replace a typ file in a gmapsupp.img simply by dragging the img to the batch file.
Edit the file ReplaceTyp.cmd to match the typ files you want to offer the users of your map.
Distribute ReplaceTyp.cmd, gmt.exe and the typ files together.


ReplaceTyp.sh (Unix)
====================
Usage:
   ReplaceTyp.sh /path/to/my/gmapsupp.img
     or
   ReplaceTyp.sh /path/to/my/gmapsupp.img myTypfile.TYP

The first version will ask for a typ file to be used as the new one, the second version tells the script directly 
which TYP file has to be used.