#!/bin/bash

# this scripts creates a single arhive, timestamped with the date.
# usage: bkarchive source_file dest_dir [none]
#   none = non-interactive

# Exit codes:
#  - 1: usage
#  - 2: tar failed

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

SRCFILE="$1"
DSTPATH="$2"
DATE=$(date "+%Y-%m-%d:%Hh_%Mm_%Ss")
DESTFILE="${DSTPATH}/archive_${DATE}.tar.bz"

# non-interactive stuff
INTERACT="YES"
if [ "$3" == "none" ]; then
	INTERACT="NONE"
fi
if [[ "$-" == *"i"* ]]; then
	INTERACT="NONE"
fi

if [ "$INTERACT" == "YES" ]; then
	HEIGHT=15
	let WIDTH=$(tput cols)-6
fi

prompt ()
{
	if [ "$INTERACT" == "YES" ]; then
		whiptail \
			--title "backuptools/bkarchive" \
			--"$1" "$2" "$HEIGHT" "$WIDTH"
		return $?
	else
		printf "$2\n"
		return 0
	fi
}

checkexit () 
{
	if [ $? == $1 ]; then
		exit $2
	fi
}

prompt "yesno" "Is this ok?\n\n - Source File: $SRCFILE\n - Dest File: $DESTFILE\n"
checkexit 1 1

echo "creating tar backup"
tar -zcvf $DESTFILE $SRCFILE
if [ $? == 0 ]; then
	prompt "msgbox" "Successful"
else
	prompt "msgbox" "Backup Failed"
	exit 2
fi

exit
