#!/bin/bash

check_root(){
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root."
        exit
    fi
}

check_root

echo -e "\n
       |----------------------|
       |USER MANAGEMENT SCRIPT|
       |----------------------|\n\n"

# Will add ability to load user files
# EX: To cross check should-be admins with shouldn't be.
echo "  [1] List all users"
echo "  [2] Cross check users with file"

read -p "> " choice

# Using wheel since I'm on Void.
sudo_group=wheel

if [ $choice = "1" ]
then
    echo -e "USING $sudo_group AS ADMIN GROUP\n"
    # getent passwd | awk -F: '{ print $1}'
    users=$(ls /home)
    # echo $users

    echo -e "USERNAME      ACCOUNT TYPE       PASSWORD SET"
    echo -e "---------------------------------------------"

    while IFS=' ' read -ra ADDR; do
        for user in "${ADDR[@]}"; do
            echo -n "$user"
            output=$(groups $user)
            if [[ $output == *"$sudo_group"*  ]] then
                echo -n "            ADMIN"
            else
                echo -n "            STANDARD"
            fi

            output=$(cat /etc/shadow | grep $user)
            if [[ ${#output} -gt 50 ]] then
                # If the strlen of the user's shadow entry is longer than 50
                # chars, we can assume that the encrypted password is the
                # reason for it being that long. Let user know username has
                # password.
                echo "            YES"
            else
                echo "               NO"
            fi

            echo ""

        done
    done <<< "$users"

elif [ $choice = "2"  ]
then
    read -p "Enter list of users file > " users_file
    read -p "Enter list of admin file > " admin_file

    if [ ! -f $users_file ]; then
        echo -e "Could not find $users_file\n"
        exit
    fi
    if [ ! -f $admin_file ]; then
        echo -e "Could not find $admin_file\n"
        exit
    fi

    echo " ... "

else
    echo -e "Invalid option.\n"

fi

