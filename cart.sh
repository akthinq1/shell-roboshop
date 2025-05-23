#!/bin/bash

START_TIME=$(date +%s)
red="\e[31m"
green="\e[32m"
Y="\e[33m"
reset="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=echo $0 | cut -d "." -f1
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
check_root=$(id -u)
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

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping data in cart"

npm install &>>$LOG_FILE
VALIDATE $? "installing npm packages"

cp $SCRIPT_DIRECTORY/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart"

END_TIME=$(date +%s)

TOTAL_TIME=$($END_TIME - $START_TIME)
echo -e "Time taken to complete the script $Y TIME:: $TOTAL_TIME in seconds $N" | tee -a &>>LOG_FILE
