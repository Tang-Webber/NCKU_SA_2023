#!/bin/bash
usage() {
echo -n -e "\nUsage: sahw2 $(seq 1 "$#").sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5:MD5 hashes to validate input files.\n-i: Input files.\n"
}

declare -a hashes

function md5_checksum(){
    n=0
    for i in "$@"; do
        if [ "$i" == "--sha256" ] ; then
            echo "Error: Only one type of hash function is allowed." >&2
            exit 1
        fi
        ((n++))
        if [ "$i" == "-i" ] ; then
            ((n--))
            break
        fi
    done
    
    if [ "$(($# / 2))" -ne "$n" ] ; then
        echo "Error: Invalid values." >&2
        exit 1
    fi    

    for i in $(seq 1 "$n"); do
        #recognize file extension
        #calculate hash value
        j=$(($i+$n+1))
        md5_hash=$(md5sum ${!j} | awk '{ print $1 }')
        #compare hash value and input hash 
        if [ "$md5_hash" != "${!i}" ] ; then
            echo "Error: Invalid checksum." >&2
            exit 1
        else
            echo "yes"
        fi
    done
    
    #for file in "$@"; do
    #    file_type=$(file -b --mime-type "$file")
    #    case "$file_type" in
    #        application/json*)
    #            jq '.' "$file"
    #        ;;
    #        text/csv*)
    #            csvlook "$file"
    #        ;;
    #    esac
    #sdone





}

sha256_checksum(){
    echo "??"
}

case $1 in
    "--md5")
        shift
        md5_checksum "$@";;
    "--sha256")
        shift
        sha256_checksum "$@";;
    "-h")
        usage
        exit 0;;
    *)
        echo "Error: Invalid arguments." >&2
        usage
        exit 1;;
esac 
