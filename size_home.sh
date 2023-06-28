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

# Ce script classera les utilisateurs du plus au moins gourmand en espace disque grâce à
# l'algorithme "tri cocktail" que vous implémenterez.
# afficger sour la forme 
# user1:2.5G,user2:1.2G,user3:0.5G,user4:0.1G

function get_home_directories_size() {
    # user1:2.5G,user2:1.2G,user3:0.5G,user4:0.1G
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
