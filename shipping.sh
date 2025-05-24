#!bin/bash

START_TIME=$(date +%s)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
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

#password for mysql
echo -e "$B Enter MYSQL PASSWORD : $N" ; read MYSQL_ROOT_PASSWD &>>$LOG_FILE

VALIDATE () {
       if [ $1 -eq 0 ]
    then
        echo -e " $2...is $green success $reset" | tee -a $LOG_FILE
    else
        echo -e " $2..... is $red failure $reset" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y
VALIDATE $? "Installing Maven and Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app 

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip
VALIDATE $? "unzipping shipping component"

mvn clean package 
mv target/shipping-1.0.jar shipping.jar 

systemctl daemon-reload
systemctl enable shipping 
systemctl start shipping

dnf install mysql -y 

mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p$MYSQL_ROOT_PASSWD < /app/db/schema.sql
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p$MYSQL_ROOT_PASSWD < /app/db/app-user.sql 
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p$MYSQL_ROOT_PASSWD < /app/db/master-data.sql

systemctl restart shipping

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE