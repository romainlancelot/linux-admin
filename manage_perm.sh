#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'


# Vous allez créer un script permettant de contrôler les exécutables pour lesquels le SUID
# et/ou le SGID est activé. Il permettra de générer une liste de ces fichiers et de la comparer,
# si elle existe, avec la liste créée lors du précédent appel du script.
# Si les 2 listes sont différentes, un avertissement s'affiche avec la liste des différences. Vous
# afficherez la date de modification des fichiers litigieux.

function get_suid_list() {
    suid_list=$(find / -perm -u=s -type f 2>/dev/null)
}

function get_sgid_list() {
    sgid_list=$(find / -perm -g=s -type f 2>/dev/null)
}

function get_diff() {
    for file in $(echo $files | tr " " "\n")
    do
        if [ $(echo $file | cut -c1) == "+" ]
        then
            echo -e "$file (edit date: $(stat -c %y $(echo $file | cut -c2-) | cut -d" " -f1))"
        else
            echo -e "$file => deleted"
        fi
    done
}

function  compare_previous() {
    if [ -f ./perm_list ]
    then
        previous_suid_list=$(cat ./perm_list | grep "### SUID LIST ###" -A 1000 | grep "### SGID LIST ###" -B 1000 | grep -v "### SGID LIST ###" | grep -v "### SUID LIST ###")
        if [ "$previous_suid_list" != "$suid_list" ]
        then
            echo -e "$ORANGE[WARNING]$NC The SUID list has changed"
            files=$(diff <(echo "$previous_suid_list" | tr " " "\n") <(echo "$suid_list" | tr " " "\n") | grep -E "^<|^>" | sed 's/^< /-/g' | sed 's/^> /+/g')
            get_diff
        else
            echo -e "$GREEN[OK]$NC The SUID list has not changed"
        fi

        previous_sgid_list=$(cat ./perm_list | grep "### SGID LIST ###" -A 1000 | grep -v "### SGID LIST ###")
        if [ "$previous_sgid_list" != "$sgid_list" ]
        then
            echo -e "$ORANGE[WARNING]$NC The SGID list has changed"
            files=$(diff <(echo "$previous_sgid_list" | tr " " "\n") <(echo "$sgid_list" | tr " " "\n") | grep -E "^<|^>" | sed 's/^< /-/g' | sed 's/^> /+/g')
            get_diff
        else
            echo -e "$GREEN[OK]$NC The SGID list has not changed"
        fi
    fi
}

function generate_file() {
    echo "### SUID LIST ###" > ./perm_list
    echo $suid_list | tr " " "\n" >> ./perm_list
    echo "### SGID LIST ###" >> ./perm_list
    echo $sgid_list | tr " " "\n" >> ./perm_list
}


# require sudo rights to run this script
if [ $(id -u) -ne 0 ]
then
    echo -e "$RED[ERROR]$NC This script must be run as root (sudo)"
    exit 4
fi


get_suid_list
get_sgid_list
compare_previous
generate_file

echo -e "$GREEN[OK]$NC The file perm_list has been generated"
