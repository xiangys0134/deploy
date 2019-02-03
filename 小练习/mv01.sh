#!/bin/bash
#
#
DirectoryFile=/root
BaseDir=`dirname $0`

MoveFile() {
    cd ${DirectoryFile}
    ls -1 *gz|while read file
    do
        NewFile=`echo ${file%.tar.gz}aaa.tar.gz`
        echo "mv ${file} ${NewFile}"
    done

}

MoveFile_awk() {
    cd ${DirectoryFile}
    find ./ -maxdepth 1 -name "*tar.gz" -type f |awk -F 'tar.gz' '{print "mv "$0 " "$1"bbb.tar.gz"}' 

}

#MoveFile
MoveFile_awk
