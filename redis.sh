#!/bin/bash

START_TIME=$(date +%s)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER=""/var/log/roboshop-logs
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIRECTORY=$PWD
check_root=$(id -u)

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $check_root != 0 ]
then 
    echo -e "$R ERROR:: Run script with root access $N" | tee -a $LOG_FILE
else
    echo -e "$G Script running with root access... No issue $N" | tee -a $LOG_FILE
fi

VALIDATE () {
       if [ $1 -eq 0 ]
    then
        echo -e " $2...is $green success $reset" | tee -a $LOG_FILE
    else
        echo -e " $2..... is $red failure $reset" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default Redis version"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i -e "s/127.0.0.1/0.0.0.0/g" -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis 
VALIDATE $? "Enabling Redis"

systemctl start redis
VALIDATE $? "Started Redis"

END_TIME=$(date +%s)

TOTAL_TIME=$(( $END_TIME-$START_TIME))
echo -e "Time taken to complete the script $Y TIME:: $TOTAL_TIME in seconds $N" | tee -a $LOG_FILE