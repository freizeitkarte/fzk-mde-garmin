#!/bin/sh

# Kopieren der FZK-Entwicklungsumgebung (Garmin)
# Version 0.4 - 2013/02/10, Klaus Tockloth
#
# Anmerkungen:
# - Verzeichnisse mit Bewegungsdaten werden nicht kopiert (install, source)

# set -o xtrace

if [ $# -ne 2 ]; then
  echo " "
  echo "Benutzung : $0  <Quellverzeichnis>         <Zielverzeichnis>"
  echo "Beispiel  : $0  Freizeitkarte-Entwicklung  Freizeitkarte-Entwicklung-Neu"
  echo " "
  exit 1
fi

# set -o verbose

SOURCEDIR=$1
DESTDIR=$2

mkdir $DESTDIR
cp    $SOURCEDIR/*               $DESTDIR
cp -r $SOURCEDIR/bounds          $DESTDIR
cp -r $SOURCEDIR/cities          $DESTDIR
cp -r $SOURCEDIR/nsis            $DESTDIR
cp -r $SOURCEDIR/poly            $DESTDIR
cp -r $SOURCEDIR/sea             $DESTDIR
cp -r $SOURCEDIR/style           $DESTDIR
cp -r $SOURCEDIR/tools           $DESTDIR
cp -r $SOURCEDIR/translations    $DESTDIR
cp -r $SOURCEDIR/TYP             $DESTDIR
cp -r $SOURCEDIR/windows         $DESTDIR

# Correct executable rights (just to be sure)
#set -x 
cd $DESTDIR

chmod u+x,g+x,o+x cpfzk.sh mt.pl

find nsis -type f -exec chmod u+x,g+x,o+x {} \;

find tools/dud -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/gmapi-builder -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/IMGinfo -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/jmc -type f -exec chmod u+x,g+x,o+x {} \;
find tools/osmconvert -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/osmfilter -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/ppp -type f  -exec chmod u+x,g+x,o+x {} \;
find tools/zip -type f  -exec chmod u+x,g+x,o+x {} \;

find windows -type f  -exec chmod u+x,g+x,o+x {} \;
