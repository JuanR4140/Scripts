#! /bin/bash

echo "Decoder"
echo "[1] Input text"
echo "[2] Input file"

read -p "> " choice

if [ $choice = "1" ] # Will implement more text decodings and such as we come across them/think about them
then
	read -p "Enter text to decode: " text
	echo "Base 64: "
	echo `echo $text | base64 --decode`
	echo ``
	echo "Hex: "
	echo `echo $text | xxd -r -p`

elif [ $choice = "2" ] # Will implement decoding files and such as we come across them/think about them
then
	read -p "Enter file to decode: " file

else
	echo "Invalid choice"
fi
