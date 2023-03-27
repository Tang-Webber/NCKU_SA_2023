 #!/usr/local/bin/bash
usage() {
echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files.\n"
}

export NUM=0;
export Hash_First=0;

md5_checksum(){
    for i in "$@"; do
        if [ "$i" == "--sha256" ] ; then
            echo -n "Error: Only one type of hash function is allowed." >&2
            exit 1
        fi
    done
    for i in "$@"; do
        if [ "$i" == "-i" ] ; then
            break
        fi
        if [ "$i" == "--md5" ] ; then
            ((Hash_First=-NUM-1))
            break
        fi
        ((NUM++))
    done
    
    if [ "$(($# / 2))" -ne "$NUM" ] ; then
        echo -n "Error: Invalid values." >&2
        exit 1
    fi    

    for i in $(seq 1 "$NUM"); do
        #recognize file extension
        #calculate hash value
        x=$(($i+$NUM+$Hash_First+1))
        md5_hash="$(md5sum "${!x}" | awk '{ print $1 }')"
        #compare hash value and input hash 
        y=$(($i-$Hash_First))
        if [ "$md5_hash" != "${!y}" ] ; then
            echo -n "Error: Invalid checksum." >&2
            exit 1
        fi
    done
}

sha256_checksum(){
    for i in "$@"; do
        if [ "$i" == "--md5" ] ; then
            echo -n "Error: Only one type of hash function is allowed." >&2
            exit 1
        fi
    done
    for i in "$@"; do
        if [ "$i" == "-i" ] ; then
            break
        fi
        if [ "$i" == "--sha256" ] ; then
            ((Hash_First=-NUM-1))
            break
        fi
        ((NUM++))
    done
    
    if [ "$(($# / 2))" -ne "$NUM" ] ; then
        echo -n "Error: Invalid values." >&2
        exit 1
    fi    

    for i in $(seq 1 "$NUM"); do
        #recognize file extension
        #calculate hash value
        x=$(($i+$NUM+$Hash_First+1))
        sha256_hash="$(sha256sum "${!x}" | awk '{ print $1 }')"
        #compare hash value and input hash 
        y=$(($i-$Hash_First))
        if [ "$sha256_hash" != "${!y}" ] ; then
            echo -n "Error: Invalid checksum." >&2
            exit 1
        fi
    done
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
    "-i")
        for k in "$@"; do
            if [ "$k" == "--md5" ] ; then
                shift
                md5_checksum "$@"
                break
            fi
            if [ "$k" == "--sha256" ] ; then
                shift
                sha256_checksum "$@"
                break
            fi
        done
        ;;
    *)
        echo -n "Error: Invalid arguments." >&2
        usage
        exit 1;;
esac 

declare -a usernames
declare -a passwords
declare -a shells
declare -A groups

for i in $(seq 1 "$NUM"); do
    x=$(($i+$NUM+$Hash_First+1))
    file_type=$(file "${!x}")
    if [[ "$file_type" =~ CSV ]] ; then 
        usernames+=( $(awk -F',' 'NR>1 {print $1}' ${!x}) )
        #passwords+=( $(awk -F',' 'NR>1 {print $2}' ${!x}) )
        #shells+=( $(awk -F',' 'NR>1 {print $3}' ${!x}) )
        #groups+=( $(awk -F',' 'NR>1 {print $4}' ${!x}) )
    elif [[ "$file_type" =~ json ]] ; then
        usernames+=$(cat "test2.json" | jq -r '.[].username' | tr '\n' ' ')
        #passwords+=$(cat "test2.json" | jq -r '.[].password' | tr '\n' ' ')
        #shells+=$(cat "test2.json" | jq -r '.[].shell' | tr '\n' ' ')
        #groups+=$(cat "test2.json" | jq '.[].groups[]' | tr '\n' ' ')
    else
        echo "Error: Invalid file format."
        exit 1
    fi
done

echo -n "This script will create the following user(s): "
echo -n "${usernames[@]}"
echo -n " Do you want to continue? [y/n]:"
read confirm
if [ "$confirm" == "n" ] || [ -z "$confirm" ] ; then
    exit 0
fi



