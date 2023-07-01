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
    home_directories_size=$(du -sh $home_directories | sort -n | tr "\n" "," | sed 's/,$//')
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

echo -e "$GREEN[OK]$NC The 5 biggest home directories are:"
echo $home_directories_size | tr "," "\n" | sort -n -r | sed 's/\/home\///g' | head -n 5

for home_directory in $(echo $home_directories | tr " " "\n")
do
    bashrc="$home_directory/.bashrc"
    if grep -q "### USERS HOME DIRECTORIES SIZE ###" $bashrc
    then
        sed -i '/### USERS HOME DIRECTORIES SIZE ###/,/### END USERS HOME DIRECTORIES SIZE ###/d' $bashrc
    fi
    
    echo "### USERS HOME DIRECTORIES SIZE ###" >> $bashrc
    echo "echo $home_directories_size | tr \",\" \"\n\" | sort -n -r | sed 's/\/home\///g' | head -n 5" >> $bashrc
    
    # modifierez le fichier .bashrc de chaque utilisateur pour qu'il voit s'afficher la taille de
    # son répertoire personnel ainsi qu'un avertissement s'il occupe plus de 100Mo.
    # Les tailles devront s'afficher sous la forme "XGo,YMo,Zko et Toctets".

    home_directory_size=$(du -sh $home_directory | cut -f1)
    echo -e "$GREEN[OK]$NC The home directory of $home_directory is $home_directory_size"
    echo "echo Your home directory size is $home_directory_size" >> $bashrc

    if [ $(echo $home_directory_size | cut -d"M" -f1) -gt 100 ]
    then
        echo -e "$ORANGE[WARNING]$NC The home directory of $home_directory is bigger than 100Mo"
        echo "echo -e \"$ORANGE[WARNING]$NC Your home directory size is bigger than 100Mo\"" >> $bashrc
    fi

    echo "### END USERS HOME DIRECTORIES SIZE ###" >> $bashrc
done

echo -e "$GREEN[OK]$NC The 5 biggest home directories will be displayed when you open a new terminal"
