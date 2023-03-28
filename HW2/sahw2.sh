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
declare -a tmpuname
declare -a passwords
declare -a tmppw
declare -a shells
declare -a tmpsh
declare -a groups

usernum=0
for j in $(seq 1 "$NUM"); do
    x=$(($j+$NUM+$Hash_First+1))
    file_type=$(file -b "${!x}")
    if [[ "$file_type" =~ CSV ]] ; then 
        tmpuname=( $(awk -F',' 'NR>1 {print $1}' ${!x}) )
        tmppw+=( $(awk -F',' 'NR>1 {print $2}' ${!x}) )
        tmpsh+=( $(awk -F',' 'NR>1 {print $3}' ${!x}) )
        #groups
        data=$(awk -F',' 'NR>1 {print $4}' ${!x})
        IFS=$'\n' read -d '' -ra arr <<< "$data"
        for k in "${!arr[@]}"; do
            groups["$usernum"]="${arr[$k]}"
            ((usernum++))
        done
        usernames+=("${tmpuname[@]}")
        for str in ${tmppw[@]} ; do
            for n in $str ; do
                n=$(echo "$n" | sed 's/ //g')
                passwords+=("$n")
            done
        done
        for str in ${tmpsh[@]} ; do
            for n in $str ; do
                n=$(echo "$n" | sed 's/ //g')
                shells+=("$n")
            done
        done
        unset tmpuname
        unset tmppw
        unset tmpsh
        declare -a tmpuname
        declare -a tmppw
        declare -a tmpsh
    elif [[ "$file_type" =~ JSON ]] ; then
        tmpuname=" $(cat "${!x}" | jq -r '.[].username' | tr '\n' ' ')"
        passwords+=" $(cat "${!x}" | jq -r '.[].password' | tr '\n' ' ')"
        shells+=" $(cat "${!x}" | jq -r '.[].shell' | tr '\n' ' ')"
        groups+=" $(cat "${!x}" | jq -r '.[].groups | @sh' | tr '\n' ' ')"
        usernames+=( "${tmpuname[@]}" )
        for n in $tmppw ; do
            n=$(echo "$n" | sed 's/ //g')
            passwords+=("$n")
        done
        for n in $tmpsh ; do
            n=$(echo "$n" | sed 's/ //g')
            shells+=("$n")
        done
        unset tmpuname
        unset tmppw
        unset tmpsh
        declare -a tmpuname
        declare -a tmppw
        declare -a tmpsh
        usernum=" $(echo "${usernames[@]}" | tr ' ' '\n' | wc -l)"
    else
        echo -n "Error: Invalid file format."  >&2
        exit 1
    fi
done

echo -n "This script will create the following user(s): "
echo -n ${usernames[@]}
echo -n " Do you want to continue? [y/n]:"
read -r confirm
if [ "$confirm" == "n" ] || [ -z "$confirm" ] ; then
    exit 0
fi

n=0
for user in ${usernames[@]}; do
    password=$(echo ${passwords[n]}} | sed 's/ //g')
    shell=$(echo ${shells[n]} | sed 's/ //g')
    # Check if user already exists
    if id "$user" >/dev/null 2>&1; then
        echo "Warning: user ${user} already exists."
        ((n++))
        continue
    fi
    
    # Create user with username, password, and shell
    pw useradd -m -s "${shell}" -n "$user"
    sudo echo "${password}" | pw usermod -n "$user" -h 0 | bash

    # Add user to groups
    for group in ${groups[n]}; do
        group=$(echo $group | sed 's/ //g')
        # Check if group already exists
        if ! getent group "${group}" >/dev/null 2>&1; then
            # Group does not exist, create it
            pw groupadd "${group}"
        fi
        # Add user to group
        pw groupmod "${group}" -m "${user}"
    done
    ((n++))
done