#!/bin/bash

mkdir result_file
cd result_file
touch result.log
echo "This is my result file" > result.log
date
<<<<<<< HEAD
echo $hostname
echo $whoami
=======
echo hostname
echo whoami
>>>>>>> fbd957097c7bfe222468b33af5c097c2e9e05ec8
df -h
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

current_date=$(date)
echo "My name is $name" >> result.log