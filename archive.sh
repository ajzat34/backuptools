#!/bin/bash

# This scripts creates a single backup, timestamped with the date
# usage: ./createbackup.sh source destination_dir name
# example: ./createbackup.sh /server/data /mass/backups/server serverdata
#  -> creates /mass/backups/server/serverdata(timestamp).tar.bz

# Check for some stuff
if [ $(command -v whiptail) == "" ]; then
	echo "you need to install whiptail or add it to your path"
	exit 1
fi

if [ "$1" == "" ]; then
	echo "Missing source path"
	exit 1
fi

if [ "$2" == "" ]; then 
        echo "Missing destination path"
        exit 1
fi

if [ "$3" == "" ]; then
        echo "Missing prefix"
        exit 1
fi

# Set box size
HEIGHT=20
WIDTH=80

msgbox ()
{
	whiptail \
		--title "$1" \
		--msgbox "$2" "$HEIGHT" "$WIDTH"
}

yesno ()
{
        whiptail \
                --title "$1" \
                --yesno "$2" "$HEIGHT" "$WIDTH"
}

SRCFILE=$1
DESTDIR=$2
DATE=$(date "+%Y-%m-%d:%HH:%MM:%SS") # change this if you want a different timestamp
DESTFILE="${DESTDIR}/${3}_${DATE}.tar.bz"

yesno "BackupTools/ Create permanent backup" "About to create a backup with these files:\n\n - Source Directory/File: $SRCFILE\n - Backup file: $DESTFILE\n\nIs this ok?"
if [ $? != 0 ]; then
	echo "Backup of $SRCFILE aborted"
	exit 0
fi

echo "Creating backup of $SRCFILE to $DESTFILE"

tar -zcvf $DESTFILE $SRCFILE
if [ $? == 0 ]; then
	msgbox "BackupTools/ Create permanent backup" "Successful"
	exit 0
else
	msgbox "BackupTools/ Create permanent backup" "Archive Failed"
	exit 2
fi
