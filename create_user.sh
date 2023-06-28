#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'


function check_user_exists() {
    if [ $(grep -c "^$1:" /etc/passwd) -ne 0 ]
    then
        new_login=$1
        i=1
        while [ $(grep -c "^$new_login:" /etc/passwd) -ne 0 ]
        do
            new_login=$1$i
            i=$(($i+1))
        done
        echo -e "$ORANGE[WARNING]$NC User $1 already exists, new login is $new_login"
        login=$new_login
    fi
}

function check_home_directory() {
    if [ -d /home/$1 ]
    then
        rm -rf /home/$1
        echo -e "$ORANGE[WARNING]$NC Directory /home/$1 already exists: it has been deleted"
    fi
}

function create_user() {
    useradd -c "$2 $3" -m -s /bin/bash $1
    echo "$1:$5" | chpasswd
    if [ $4 = "oui" ]
    then
        usermod -aG sudo $1
        echo " - User $1 is sudoer"
    fi
    echo -e "$GREEN[OK]$NC User $1 created"
}

function assign_groups() {
    # assign groups and the first one is the primary group and create if not exists
    if [ -z $1 ]
    then
        echo -e "$RED[ERROR]$NC No group specified: default group is $login"
    else
        for group in $(echo $1 | tr "," "\n")
        do
            if [ $(grep -c "^$group:" /etc/group) -eq 0 ]
            then
                groupadd $group
                echo " - Group $group created"
            fi
            if [ -z $primary_group ]
            then
                if [ $(grep -c ":$group:" /etc/group) -ne 0 ]
                then
                    primary_group=$(grep ":$group:" /etc/group | cut -d: -f1)
                    echo " - Primary group $group already exists and is associated to another user: primary group set to $primary_group"
                else
                    primary_group=$group
                    usermod -g $group $login
                fi
            else
                usermod -aG $group $login
            fi
        done
        echo -e "$GREEN[OK]$NC User $login assigned to groups: $1 with primary group $primary_group"
    fi
}

function generate_files() {
    if [ ! -d /home/$1 ]
    then
        echo -e "$RED[ERROR]$NC Directory /home/$1 does not exist"
        exit 5
    fi
    cd /home/$1
    echo " - Generating files in /home/$1 ..."
    for i in $(seq 1 $((RANDOM%6+5)))
    do
        dd if=/dev/urandom of=file$i bs=1 count=$((RANDOM%10000000+5000000)) 2> /dev/null
    done
    echo -e "$GREEN[OK]$NC Files generated in /home/$1: $(ls -l | grep -c "^-")"
}


# require sudo rights to run this script
if [ $(id -u) -ne 0 ]
then
    echo -e "$RED[ERROR]$NC This script must be run as root (sudo)"
    exit 4
fi

if [ $# -ne 1 ]
then
    echo -e "$ORANGE[WARNING]$NC Usage: $0 <file>"
    exit 1
fi

if [ ! -f $1 ]
then
    echo -e "$RED[ERROR]$NC $1 is not a file"
    exit 2
fi


if [ $(grep -c "^[^:]*:[^:]*:[^:]*:[^:]*:[^:]*$" $1) -ne $(wc -l $1 | cut -d" " -f1) ]
then
    echo -e "$RED[ERROR]$NC File $1 has wrong format"
    exit 3
else
    echo -e "$GREEN[OK]$NC File $1 has correct format\n"
fi


while read line
do
    firstname=$(echo $line | cut -d: -f1)
    lastname=$(echo $line | cut -d: -f2)
    groups=$(echo $line | cut -d: -f3)
    sudo=$(echo $line | cut -d: -f4)
    password=$(echo $line | cut -d: -f5)

    login=$(echo $firstname | cut -c1)$(echo $lastname)
    login=$(echo $login | tr '[:upper:]' '[:lower:]')

    check_user_exists $login
    check_home_directory $login

    create_user $login $firstname $lastname $sudo $password
    assign_groups $groups
    generate_files $login

    echo ""
done < $1

echo -e "$GREEN[OK]$NC All users created successfully"
exit 0
