#!/bin/bash


red="\e[31m"
green="\e[32m"
Y="\e[33m"
reset="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
root_access=$(id -u)
SCRIPT_DIRECTORY=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started and executed at: $(date)" | tee -a $LOG_FILE

if [ $root_access -ne 0 ]
then
    echo -e "$red ERROR:: run the script with root access $reset" | tee -a $LOG_FILE
    exit 1 #exit status for error
else
    echo -e "$green script is running.... no issues $reset" | tee -a $LOG_FILE
fi 

VALIDATE () {
    if [ $1 -eq 0 ] 
    then
        echo -e "$2 is... $Green successfully $reset" | tee -a $LOG_FILE
    else
        echo -e "$2 is... $Green failure $reset" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabled nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabled nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Started nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing Default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIRECTORY/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting nginx"