#!bin/bash

#create instance and assign zones

#required variables

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03884c9ac49287e7d"
INSTANCES=( "frontend" "mongodb" "mysql" "rabbitmq" "redis" "catalogue" "user" "cart" "shipping" "payment" "dispatch" )
ZONE_ID="Z06554383VBJBI4HM0QKT"
DOMAIN_NAME="akdevops.fun"

#to create all instaince at one time

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-03884c9ac49287e7d --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
        IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
        IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
    echo "Name of Instnace: $instance and IP: $IP_ADDRESS" 
done