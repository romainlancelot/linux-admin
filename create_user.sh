#!/bin/bash

# Vous allez créer un premier script permettant de créer automatiquement des utilisateurs
# utilisables. Vous utiliserez un fichier source pour cette création dont chaque ligne aura la
# structure suivante :
# prénom:nom:groupe1,groupe2,…:sudo:motdepasse
# Avant tout, vous devez vérifier que le fichier a un format correct.

function check_user_exists() {
    if [ $(grep -c "^$1:" /etc/passwd) -ne 0 ]
    then
        echo "Error: user $1 already exists"
        exit 3
    fi
}


function check_group_exists() {
    if [ $(grep -c "^$1:" /etc/group) -eq 0 ]
    then
        groupadd $1
        echo "Group $1 created"
    fi
}


if [ $# -ne 1 ]
then
    echo "Usage: $0 <file>"
    exit 1
fi

if [ ! -f $1 ]
then
    echo "Error: $1 is not a file"
    exit 2
fi

# open file and read line by line
while read line
do
    firstname=$(echo $line | cut -d: -f1)
    lastname=$(echo $line | cut -d: -f2)
    groups=$(echo $line | cut -d: -f3)
    sudo=$(echo $line | cut -d: -f4)
    password=$(echo $line | cut -d: -f5)

    check_user_exists $firstname

    for group in $(echo $groups | tr "," " ")
    do
        # check_group_exists $group
    done

    # create group
    #groupadd $groups

    # create user
    #useradd -c "$firstname $lastname" -G $groups -m -s /bin/bash $firstname

    # set password
    #echo "$firstname:$password" | chpasswd

    # set sudo
    #if [ $sudo = "oui" ]
    #then
    #    usermod -aG sudo $firstname
    #fi

done < $1

# Le login sera généré automatiquement avec la première lettre du prénom suivie du
# nom. Si un utilisateur existe déjà, il faut ajouter un chiffre à la fin de son login

login=$(echo $firstname | cut -c1)$(echo $lastname)

# • Chaque utilisateur aura, dans le champ commentaire de /etc/passwd, son prénom suivi
# de son nom, il pourra se connecter avec le login généré et le mot de passe donnés dans
# le fichier. De plus, l'utilisateur devra changer son mot de passe lors de sa première
# connexion.
# • Le premier groupe cité sera le groupe primaire de l'utilisateur, les éventuels autres
# groupes seront ses groupes secondaires. Si un groupe n'existe pas, il devra être créé
# par le script. S'il n'y a pas de groupe dans la ligne de l'utilisateur, son groupe primaire
# aura le même nom que le login de l'utilisateur.
# • Le champ sudo sera à 'oui' ou 'non' et s'il est à 'oui', l'utilisateur sera un sudoer, sinon il
# ne le sera pas.