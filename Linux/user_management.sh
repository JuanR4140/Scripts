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

    echo -e "Checking $users_file..\n"
    not_found_amnt=0
    root_rights_amnt=0
    while read -r line
    do
        not_found=true
        # echo "$line"
        while IFS=' ' read -ra ADDR; do
            for user in "${ADDR[@]}"; do
                # echo -n "$user"
                if [ $line == $user  ]; then
                    not_found=false

                    if [[ $(groups $line) == *"$sudo_group"* ]] then
                        ((root_rights_amnt++))
                        echo -e "$line found, but has ADMIN PERMISSIONS\n"
                        echo -n "Would you like to remove them? (y/n) > "
                        read should_remove_admin </dev/tty
                        if [ $should_remove_admin = "y" ]; then
                            echo -e "Removing $line..\n"
                            gpasswd -d $line $sudo_group
                            echo -e "Removed $line from $sudo_group!\n\n"
                        else
                            echo -e "Skipping operation on $line.\n\n"
                        fi
                    fi

                    output=$(cat /etc/shadow | grep $line)
                    if [ ${#output} -lt 50 ]; then
                        echo -n "User $line does not seem to have a password set. Set one? (y/n) > "
                        read should_set_password </dev/tty
                        if [ $should_set_password = "y" ]; then
                            echo -e "Setting password for $line.."
                            read -p "Enter new password: " password </dev/tty
                            echo "$line:$password" | chpasswd -c SHA512 -s 10000
                            # passwd $line
                            echo -e "Changed password for $line."
                        fi
                    fi
                fi
            done
        done <<< "$(ls /home)"

        if $not_found; then
            ((not_found_amnt++))
            echo -e "$line NOT found in provided user list.\n"
        fi

    done < "$users_file"

    echo -e "$users_file RESULTS\n----------------------\n"
    echo -e "$not_found_amnt users not found in provided user list."
    echo -e "Double check the results are correct, then delete the user with deluser.\n"
    echo -e "$root_rights_amnt users found in provided user list, but are ADMINS."
    echo -e "Double check the results are correct, then remove the user from $sudo_group with gpasswd.\n"

    echo -e "[Press ENTER to continue]"
    read trash


    echo -e "Checking $admin_file..\n"
    not_found_amnt=0
    root_rights_amnt=0
    while read -r line
    do
        # echo $line
        not_found=true
        while IFS=' ' read -ra ADDR; do
            for user in "${ADDR[@]}"; do
                # echo $user
                if [ $line == $user ]; then
                    not_found=false

                    if [[ $(groups $line) != *"$sudo_group"* ]]; then
                        echo -e "$line found, but has STANDARD PERMISSIONS\n"
                        echo -n "Would you like to add them? (y/n) > "
                        read should_add_admin </dev/tty
                        if [ $should_add_admin = "y"  ]; then
                            echo -e "Adding $line..\n"
                            usermod -aG $sudo_group $line
                            echo -e "Added $line to $sudo_group!\n\n"
                        else
                            echo -e "Skipping operation on $line.\n\n"
                        fi
                    fi

                    output=$(cat /etc/shadow | grep $line)
                    if [ ${#output} -lt 50 ]; then
                        echo -n "ADMIN $line does not seem to have a password set. Set one? (y/n) > "
                        read should_set_password </dev/tty
                        if [ $should_set_password = "y" ]; then
                            echo -e "Setting password for $line.."
                            read -p "Enter new password: " password </dev/tty
                            echo "$line:$password" | chpasswd -c SHA512 -s 10000
                            # passwd $line
                            echo -e "Changed password for $line."

                        fi
                    fi
                fi
            done
        done <<< $(ls /home) 

        if $not_found; then
            ((not_found_amnt++))
            echo -e "$line NOT found in provided admin list.\n"
        fi

    done < "$admin_file"

    echo -e "$admin_file RESULTS\n----------------------\n"
    echo -e "$not_found_amnt users not found in provided admin list."
    echo -e "Double check the results are correct, then delete the user with deluser.\n"
    echo -e "$root_rights_amnt users found in provided admin list, but have STANDARD permission."
    echo -e "Double check the results are correct, then add the user to $sudo_group with gpasswd.\n\n\n"


    not_found_amnt=0
    while IFS=' ' read -ra ADDR; do
        for user in "${ADDR[@]}"; do
            not_found=true
            while read -r line
            do
                if [ $user == $line  ]; then
                    not_found=false
                fi
            done < $users_file

            while read -r line
            do
                if [ $user == $line  ]; then
                    not_found=false
                fi
            done < $admin_file

            if $not_found; then
                ((not_found_amnt++))
                echo -e "$user NOT PRESENT WITHIN ANY GIVEN FILE.\n"
                echo -n "WOULD YOU LIKE TO REMOVE THEM? (y/n) > "
                read conf_1 </dev/tty
                if [ $conf_1 = "y" ]; then
                    echo -e "ARE YOU SURE? THIS WILL DELETE ALL OF $user'S INFORMATION."
                    echo -n "PLEASE DOUBLE CHECK THIS IS WHAT YOU WANT TO DO, THEN TYPE 'yes' > "
                    read conf_2 </dev/tty
                    if [ $conf_2 = "yes" ]; then
                        echo "REMOVING $user FROM THE SYSTEM.."
                        userdel -r $user
                        killall -u $user
                        echo "REMOVED $user FROM SYSTEM.\n\n"
                    fi
                fi
            fi

        done
    done <<< $(ls /home)

    echo -e "\n$not_found_amnt USERS NOT FOUND WITHIN ANY GIVEN FILE.\n"

    exit

else
    echo -e "Invalid option.\n"

fi

