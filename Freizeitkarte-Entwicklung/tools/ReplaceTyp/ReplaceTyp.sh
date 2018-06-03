#!/bin/bash
#=====================================================================
#
# Replace TYP files in garmin image file by means of GMapTool,
# available from www.gmaptool.eu.  This script is functional identical
# to the ReplaceTyp-Script provided by Freizeitkarte.  Use bash to get
# as low a footprint as possible. Resorting to other languages would,
# however, offer a richer solution.
#
# Last update: Thu, 2013/10/06
# Author     : Alexander Wagner
# Language   : Bash
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the license, or 
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#====================================================================

# Update 2015-10-13:
# - support for OS Darwin
# - make sure the script runs also with legacy shell, not only bash

# Try to get parameters to be able to work non-interactive
imgfile=$1
typfile=$2

# Tool to change the type file including path
if [ "`uname`" = "Darwin" ]; then
    gmt=./gmt_darwin
else
    gmt=./gmt
fi

# Check if we have a first parameter. We need this all the time as we
# need to know which image we should operate on
if [ $# -eq 0 ]; then
	echo "Please pass the imgfile you wish to change as argument:"
	echo ""
	echo "  $ ReplaceTyp.sh gmapsupp.img"
	echo ""
	exit
fi 

# Check if $imgfile is an actually existing file
if [ -f "$imgfile" ]; then
	echo ""
	echo "Changing type of $imgfile"
else
	echo ""
	echo "$imgfile does not exist or is no file."
	echo "Aborting."
	echo ""
	exit
fi

# Check if we got a second parameter, and if so, check if a file of
# that name exists. Then we will not ask for a type file but just use
# the one passed on.
if [ $# -eq 2 ]; then
	if [ -f $2 ]; then
		echo Using passed type $typfile
	else
		echo $typfile does not exist. Exiting...
		exit
	fi
fi

# If $typefile is still '' here, we need to aks the user
if [ -z "$typfile" ]; then
	echo ""
	echo "Select from the following options:"
	typA="freizeit         - standard design of all Freizeitkarten project maps"
	typB="outdoor          - design based on 'Top50' and 'ICAO' maps    "
	typC="outdoor-light    - no symbols on the areas included     "
	typD="contrast         - colors are 'stronger' in compare to 'freizeit'"
	typE="small            - optimized for GPS devices with small displays"
    typF="outdoor-contrast - similar to contrast, no symbols on areas"

	echo "  A: $typA"
	echo "  B: $typB"
	echo "  C: $typC"
	echo "  D: $typD"
	echo "  E: $typE"
    echo "  F: $typF"
	echo "  Q: Quit "
	echo ""

	echo "Enter your choice (A-E, Q): "
          # Do we run bash ?
          if [ -n "$BASH" ]; then
                    read -n 1 key
          else
                    read key
          fi

	echo ""

	typefile=''

	case "$key" in

		a|A)
			echo You selected:
			echo $typA
			typfile=freizeit.TYP
		;;

		b|B)
			echo You selected:
			echo $typB
			typfile=outdoor.TYP
		;;

		c|C)
			echo You selected:
			echo $typC
			typfile=outdoorl.TYP
		;;

		d|D)
			echo You selected:
			echo $typD
			typfile=contrast.TYP
		;;

		e|E)
			echo You selected:
			echo $typE
			typfile=small.TYP
		;;

		f|F)
			echo You selected:
			echo $typF
			typfile=outdoorc.TYP
		;;

		q|Q)
			echo Aborting by user request.
			exit
		;;
		*)
			echo Unknown type. Exiting...
			exit
		;;
	esac
fi

# If we end up here we have all parameters necessary to change the typ
# of the img-file and we know that this file exists.
# We do not know if it is a valid Garmin file nor do we know if the
# TYP file is a valid TYP, however, we leave thsi to gmt.
echo "------------------------------------------------------------"
echo "Replacing type file in '$imgfile' by '$typfile'"
echo "   Hit ctrl-c to abort..."
echo ""
sleep 5

# Here the real work begins. All the hard stuff is done by gmt, of
# course.
echo -n "Extracting Family ID: "
fid=`$gmt -i $imgfile | grep ", FID " | cut -d',' -f 2 | sed -e 's/ FID //'`

echo $fid

echo "Replacing Typ file..."
$gmt -w -y $fid $typfile
$gmt -w -x $typfile $imgfile
