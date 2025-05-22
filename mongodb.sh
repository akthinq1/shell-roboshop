#!bin/bah

#insatll packages

#requried variables
root_access=$(id -u)
red="\e[31m"
green="\e[32m"
reset="\e[0m"

#to save and check logs
LOGS_FOLDER="/var/log/mongodb-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
PACKAGES=("mysql" "python" "nginx" "httpd")

mkdir -p $LOGS_FOLDER
echo "Script started and executed at: $(date)" | tee -a $LOG_FILE

if [ $root_access -ne 0 ]
then
    echo -e "$red ERROR:: run the script with root access $reset" | tee -a $LOG_FILE
else
    echo -e "$green script is runnung...no issues $reset" | tee -a $LOG_FILE
fi

#function to validate the command is executed or not
validate () {
   
    if [ $1 -eq 0 ]
    then
        echo -e " $2...is $green success $reset" | tee -a $LOG_FILE
    else
        echo -e " $2..... is $red failure $reset" | tee -a $LOG_FILE
        exit 1
    fi
}

# install_pack () {
#     for package in $@
#     do
#         dnf list installed $package
#         if [ $? -ne 0]
#         then
#             dnf install $package -y | tee -a $LOG_FILE
#             validate $? "$package"
#             echo "package was installing"
#         else
#             echo "nothig to do"
#         fi
#     done            
# }

# install_pack 

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying MongoDB repo"  

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systectl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting monogoDB"

#change config file for ip address
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf  &>>$LOG_FILE
VALIDATE $? "Editing mongoDB file for Remote connection"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Starting monogoDB"