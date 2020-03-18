#!/bin/bash

# USAGE: bkrotate src_file dst_path n [none] (where n is the number of backups to keep) (if none is the 4th paramater, the shell will be treated as non-interactive)
#
# this script rotates existing backup in a directory, and creates a new one
# the naming looks like 1.tar.bz 2.tar.bz ect... where a higher number is newer
#    note: that n is not setting any kind of persistant value, it simply defines how many files the script will look at
#

# exit codes:
#  1: usage
#  2: does not exist
#  3: tar error
#  4: failed to rotate backups (tmpfile was removed)
#  5: failed to rotate backups (tmpfile removal failed)
#  6: failed to install new backup (tmpfile was removed)
#  7: failed to install new backup (tmpfile removal failed)
#

# Check for some stuff
if [ "$(command -v whiptail)" == "" ]; then
	echo "you need to install whiptail or add it to your path"
	exit 1
fi

if [ "$1" == "" ]; then
	echo "Missing dest path"
	exit 1
fi

if [ "$2" == "" ]; then
        echo "Missing source path"
        exit 1
fi

if [ "$3" == "" ]; then
        echo "Missing keep max"
        exit 1
fi

# non-interactive stuff
INTERACT="YES"
if [ "$4" == "none" ]; then
	INTERACT="NONE"
fi
if [[ "$-" == *"i"* ]]; then
	INTERACT="NONE"
fi


prompt ()
{
	if [ "$INTERACT" == "YES" ]; then
		whiptail \
			--title "backuptools/bkrotate" \
			--"$1" "$2" "" ""
		return $?
	else
		printf "$2\n"
		return 0
	fi
}

checkexit ()
{
	if [ $? == "$1" ]; then
		exit "$2"
	fi
}

SRCFILE="$1"
DSTPATH="$2"
KEEPMAX="$3"
TMPFILE="${DSTPATH}/tmp.backup.tar.bz"
DESTFILE="${DSTPATH}/1.tar.bz"

prompt "yesno" "Is this ok?\n\n - Source File: $SRCFILE\n - Dest Path: $DSTPATH\n - Backups to keep: $KEEPMAX"
checkexit 1 1

echo "checking source and destination files"
if [ ! -e "$SRCFILE" ]; then
  prompt "msgbox" "Source: $SRCFILE doesnt seem to exist..."
  exit 2
fi

if [ ! -d "$DSTPATH" ]; then
  prompt "msgbox" "Directory (Destination): $DSTPATH doesnt seem to exist..."
  exit 2
fi

echo "creating tmpfile at $TMPFILE"
tar -zcvf "$TMPFILE" "$SRCFILE"
if [ $? == 0 ]; then
	echo " -> successful"
else
	prompt "msgbox" "Failed to create tar of $SRCFILE. Is $DSTPATH right? is it accessable?"
	exit 3
fi

# musical chairs
echo "rotating backups:"
for (( i=$((KEEPMAX-1)); i>=1; i-- )); do
	# gen the paths
  FILE="${DSTPATH}/${i}.tar.bz"
  echo "$FILE"
	# move the file
  if [ -f "$FILE" ]; then
		NEWFILE="${DSTPATH}/$((i+1)).tar.bz"
		echo " --> $NEWFILE"
		mv "$FILE" "$NEWFILE"
		if [ $? != 0 ]; then
      echo "Rotating old backups failed... cleaning up tmpfile"
      rm "$TMPFILE"
      if [ $? != 0 ]; then
        prompt "msgbox" "FAILED!\nFailed to rotate old backups!\nFailed!\nFailed to clean up! (There is a tmp file left at $TMPFILE)"
        exit 5
      fi
      prompt "msgbox" "FAILED!\nFailed to rotate old backups!"
			exit 4
		fi
		((count++))
  fi
done

echo "Installing new backup from $TMPFILE..."
mv "$TMPFILE" "$DESTFILE"
if [ $? == 0 ]; then
  prompt "msgbox" "Successful!"
else
  echo "failed... cleaning up"
  rm "$TMPFILE"
  if [ $? != 0 ]; then
    prompt "msgbox" "FAILED!\nFailed to install new backup!\nFailed!\nFailed to clean up! (There is a tmp file left at $TMPFILE)"
    exit 7
  fi
  exit 6
fi

exit
