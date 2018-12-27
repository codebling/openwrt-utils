#!/bin/sh
#takes one argument/parameter: the name of the package which didn't install correctly and should be removed along with its dependencies
#do opkg update first
#example: ./opkgremovepartlyinstalledpackage.sh pulseaudio-daemon

echo "WARNING: INTENDED FOR OpenWRT 18.06 ONLY, USE AT OWN RISK ON OTHER VERSIONS"

if [ $# -eq 0 ]
then
  echo "Usage: opkg-cleanup.sh <packages>"
  echo "  where <packages> are a list of packages that were partially installed with opkg install"
  echo "  e.g. ./opkg-cleanup.sh gcc"
  echo "  separate multiple packages with a space, e.g. ./opkg-cleanup.sh luci-app-wol gcc"
  exit 1
fi

#update the package lists
echo "*** Updating package lists ***"
opkg update
echo "*** Done updating package lists ***"

LASTDIR=`pwd`
TEMPDIR=`mktemp -d`
cd $TEMPDIR

for PACKAGE in "$@"
do
    IS_INSTALLED=`opkg list-installed | grep -Ec "^$PACKAGE - "`
    if [ "$IS_INSTALLED" -gt 0 ]
    then
        echo "ERROR! Package $PACKAGE is listed as being installed! Remove using \"opkg remove $PACKAGE\" before trying to clean it up. Aborting..."
        break
    fi
    echo "Downloading $PACKAGE and dependencies..."
    opkg --add-dest cleanup:$TEMPDIR -d cleanup --tmp-dir $TEMPDIR --download-only install $PACKAGE
    if [ $? -eq 0 ]
    then
        for PACKAGEFILE in `ls *.ipk`
        do
            echo "Checking package file $PACKAGEFILE"
            #create a list of files in the archive
            # cat $PACKAGEFILE        #pipe raw archive contents
            # tar -Oxz ./data.tar.gz  #extract the contents of the archive's data.tar.gz to stdout
                                        # -O to stdout
                                        # -x extract files
                                        # -z ungzip
            # tar -tz                 #list files in archive
                                        # -t list files
                                        # -z ungzip
            # grep -vE '^\./$'        #remove line containing only "./"
                                        # -v return only lines that DO NOT match
                                        # -E extended regex
            # sort -r                 #sort the lines so that we delete files before we try to delete the directories containing them
            # sed 's/^\.//'           #remove '.'  at the start of every line
            FILES=`cat $PACKAGEFILE | tar -Oxz ./data.tar.gz | tar -tz | grep -vE '^\./$' | sort -r | sed 's/^\.//'`
            for PFILE in $FILES
            do
                for FILE in "/overlay$PFILE" "/overlay/upper$PFILE"
                do
                echo "Checking for $FILE"
                if [ -f $FILE -o -L $FILE ]
                then
                    echo "Removing file $FILE"
                    rm -f $FILE
                fi
                if [ -d $FILE ]
                then
                    echo "Try to remove directory $FILE (will only work on empty directories)"
                    rmdir $FILE
                fi
                done
            done
        done
    else
        echo "Failed to download package $PACKAGE or one of its depencies. Skipping remaining packages and cleaning up..."
        break
    fi
done
echo "Removing opkg package lists from ram..."
rm -Rf /tmp/opkg-lists
echo "OK. You will need to run 'opkg update' again before installing packages."
cd $LASTDIR
echo "Removing temporary directory..."
rm -Rf $TEMPDIR
echo "OK."
echo "You may need to reboot for the free space to become visible"
