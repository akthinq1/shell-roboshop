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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "downloading shipping"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping component"

mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIRECTORY/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE

dnf install mysql -y &>>$LOG_FILE

# mysql -hmysql.akdevops.fun -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE

# if [ $? -ne 0 ]
# then
#     mysql -h mysql.akdevops.fun -uroot -p$MYSQL_ROOT_PASSWD < /app/db/schema.sql &>>$LOG_FILE
#     mysql -h mysql.akdevops.fun -uroot -p$MYSQL_ROOT_PASSWD < /app/db/app-user.sql  &>>$LOG_FILE
#     mysql -h mysql.akdevops.fun -uroot -p$MYSQL_ROOT_PASSWD < /app/db/master-data.sql &>>$LOG_FILE
#     VALIDATE $? "Loading data into MySQL"
# else
#     echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
# fi

DB_EXISTS=$(mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -sse "SHOW DATABASES LIKE 'cities';")
if [ "$DB_EXISTS" != "cities" ]; then
    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -e 'CREATE DATABASE cities;' &>> "$LOG_FILE"
    VALIDATE $? "Creating cities database"
    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/schema.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading schema.sql"
    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/app-user.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading app-user.sql"
    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/master-data.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading master-data.sql"
else
    echo -e "Database data is ${y}already loaded${reset}, skipping..." | tee -a "$LOG_FILE"
fi

systemctl restart shipping &>>$LOG_FILE

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE