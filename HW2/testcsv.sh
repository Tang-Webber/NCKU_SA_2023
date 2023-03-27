#!/bin/bash

usernames=()
passwords=()
shells=()
groups=()

# Read CSV file and store data in arrays
while IFS=',' read -r username password shell groups_line || [[ -n "$username" ]]
do
    if [[ ! $username == "username" ]]; then   # skip the first line
        usernames+=("$username")
        passwords+=("$password")
        shells+=("$shell")
        tempstr=($(echo "$groups_line" | tr " " ","))   # split the groups by space and store in array
        group_arr="${tempstr#?}"
        groups+=("${group_arr[@]}")   # add the array of groups to the main groups array
    fi
done < test1.csv

for ((i=0; i<${#usernames[@]}; i++))
do
    group_str=$(IFS=' '; echo "${groups[$i]}")
    printf "%s\n" "$group_str"
done

echo "${groups[0]}"
echo "${groups[1]}"


