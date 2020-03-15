#!/bin/bash

# This scripts creates a single backup, timestamped with the date
# usage: ./createbackup.sh source destination_dir count [nointer] # nointer means non-interactive
# example: ./createbackup.sh /server/data /mass/backups/server 5
# -> moves /mass/backups/1.tar.bz -> /mass/backups/2.tar.bz ect.. up to 5 after the main backup, so 6 will be kept including the new one
# -> creates /mass/backups/1.tar.bz

# exit codes:
# 0 - all good
# 1 - catchall (probably usage related)
# 2 - creating new backup
# 3 - rotating
# 4 - placing new backup

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
        echo "Missing keep max"
        exit 1
fi
# load stuff
SRCFILE=$1
DSTPATH=$2
KEEPMAX=$3
# check for interactive shell, and interactive param
NOINTER="NO"
if [ "$4" == "none" ]; then
	NOINTER="YES"
fi
if [ "$-" == *"i"* ]; then
	NOINTER="YES"
fi
echo "skip interactive: $NOINTER"
DATE=$(date "+%Y-%m-%d:%HH:%MM:%SS") # change this if you want a different timestamp
NEWFIRSTFILE="${DSTPATH}/1.tar.bz"
count=0

# whiptail stuff
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

if [ $NOINTER == "YES" ]; then
		printf "About to roll a backup with these options:\n- Source Directory/File: $SRCFILE\n - Backup path: $DSTPATH\n - New File: $NEWFILE\n - Max to keep: $KEEPMAX\n"
else
	yesno "BackupTools/ rotate backup" "About to roll a backup with these options:\n\n - Source Directory/File: $SRCFILE\n - Backup path: $DSTPATH\n - New File: $NEWFIRSTFILE\n - Max to keep: $KEEPMAX\n\nIs this ok?"
	if [ $? != 0 ]; then
		echo "Backup of $SRCFILE aborted"
		exit 0
	fi
fi

# tar the backup
TMPFILE="$(mktemp /tmp/rotatebackup.XXXXXXXXX.tar.bz)"
echo "backing up to: $TMPFILE..."
tar -zcvf $TMPFILE $SRCFILE
if [ $? != 0 ]; then
	msgbox "BackupTools/ rotate backup" "Failed to create new backup! Aborting!"
	exit 2
fi

# musical chairs
echo "shifting old backups"
for (( i=$KEEPMAX; i>=1; i-- )); do
	# gen the paths
  FILE="${DSTPATH}/${i}.tar.bz"
  echo "Checking $FILE"
	# move the file
  if [ -f "$FILE" ]; then
		NEWFILE="${DSTPATH}/$[i+1].tar.bz"
		echo "... -> $NEWFILE"
		mv $FILE $NEWFILE
		if [ $? != 0 ]; then
			if [ $NOINTER == "YES" ]; then
					echo "Error rotating old backups!"
			else
				msgbox "BackupTools/ rotate backup" "Error rotating old backups!"
			fi
			exit 3
		fi
		((count++))
  fi
done

sleep 1
echo "placing new backup"
mv $TMPFILE $NEWFIRSTFILE
if [ $? != 0 ]; then
	if [ $NOINTER == "YES" ]; then
			echo "Failed to place new backup file!"
	else
		msgbox "BackupTools/ rotate backup" "Failed to place new backup file!"
	fi
	exit 4
fi

if [ $NOINTER != "YES" ]; then
	msgbox "BackupTools/ rotate backup - Success!" "Success!\n - Rotated $count backups\n - Created new backup\n"
fi
