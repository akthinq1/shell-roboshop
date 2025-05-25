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
echo -e "$B Enter MYSQL PASSWORD : $N" ; read MYSQL_PASSWORD &>>$LOG_FILE

VALIDATE () {
       if [ $1 -eq 0 ]
    then
        echo -e " $2...is $green success $reset" | tee -a $LOG_FILE
    else
        echo -e " $2..... is $red failure $reset" | tee -a $LOG_FILE
        exit 1
    fi
}



dnf install mysql-server -y
VALIDATE $? "installing mysql server"

systemctl enable mysqld
VALIDATE $? "enabling mysql server"

systemctl start mysqld  
VALIDATE $? "starting mysql server"

#setup and conigure mysql database
mysql_secure_installation --set-root-pass $MYSQL_PASSWORD
VALIDATE $? "Configuing MYSQL_ROOT_PASSWORD"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

# DB_EXISTS=$(mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -sse "SHOW DATABASES LIKE 'cities';")
# if [ "$DB_EXISTS" != "cities" ]; then
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -e 'CREATE DATABASE cities;' &>> "$LOG_FILE"
#     VALIDATE $? "Creating cities database"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/schema.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading schema.sql"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/app-user.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading app-user.sql"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/master-data.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading master-data.sql"
# else
#     echo -e "Database data is ${y}already loaded${reset}, skipping..." | tee -a "$LOG_FILE"
# fi