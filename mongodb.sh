#!bin/bah

#insatll packages

#requried variables
root_access=$(id -u)
red=\e[31m
green=\e[32m
reset=\e[0m

if [$root_access -ne 0 ]
then
    echo "ERROR:: run the script with root access"
else
    echo "script success fully...no issues"
fi