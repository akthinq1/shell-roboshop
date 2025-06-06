#!/bin/bash

#required varaiables
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs:20"

#find user is already created or not, if not created create system user
id roboshop
if [ $? != 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop is alredy created and available ... $Y SKIPPING $reset"
fi

mkdir -p /app
VALIDATE $? "app directory is created"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping data in catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "installing npm packages"

cp $SCRIPT_DIRECTORY/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIRECTORY/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copied mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE 
VALIDATE $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.akdevops.fun --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -le 0 ]
then
    mongosh --host mongodb.akdevops.fun </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi

