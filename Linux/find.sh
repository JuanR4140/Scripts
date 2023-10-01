#! /bin/bash

read -p "Enter path to search: " path
read -p "Enter file extension to look for: " ext

find $path -type f -name "*$ext"
