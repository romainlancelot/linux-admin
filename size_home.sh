#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'


function get_human_users() {
    users=$(cut -d: -f1,3 /etc/passwd | egrep ':[0-9]{4}$' | cut -d: -f1)
}

function get_home_directories() {
    for user in $users
    do
        home_directories="$home_directories $(cat /etc/passwd | grep "^$user:" | cut -d: -f6)"
    done
}

function get_home_directories_size() {
    home_directories_size=""
    for home_directory in $home_directories
    do
        home_directories_size="$home_directories_size,$home_directory:$(du -sh $home_directory | cut -f1)"
    done
    home_directories_size=$(echo $home_directories_size | cut -c2-)
}


# require sudo rights to run this script
if [ $(id -u) -ne 0 ]
then
    echo -e "$RED[ERROR]$NC This script must be run as root (sudo)"
    exit 4
fi


get_human_users
get_home_directories
get_home_directories_size
echo $home_directories_size


for user in $users
do
    echo -n "$user: "
    echo $home_directories_size | tr "," "\n" | grep "$user:" | cut -d: -f2

done