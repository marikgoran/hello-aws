#!/bin/bash 

#init
KEY=flask-key-gmarik
GROUP=flask-group-gmarik

#prep work
echo "Creating security group and ssh key..."
# make sure the key file exists and the key with that name is not in AWS
if [[ ! -f $KEY.pem ]]
then
    aws ec2 create-key-pair --key-name $KEY --query 'KeyMaterial' --output text > $KEY.pem || { echo "Failed to create a new key, exiting"; exit 1; }
    chmod 400 $KEY.pem  
else
    echo "The key $KEY exists, continuing without changes"
fi
# create new group or if the group exists, do not make any changes
aws ec2 describe-security-groups --group-names $GROUP &> /dev/null || { \
        aws ec2 create-security-group --group-name $GROUP --description "security group for flask"; 
        aws ec2 authorize-security-group-ingress --group-name $GROUP --protocol tcp --port 22 --cidr 0.0.0.0/0 
        aws ec2 authorize-security-group-ingress --group-name $GROUP --protocol tcp --port 8000 --cidr 0.0.0.0/0
        } 
#main
echo "Creating new instance ..."
instance=$( aws ec2 run-instances --image-id ami-9abea4fb --security-groups $GROUP --count 1 --instance-type t2.micro --key-name $KEY  --query 'Instances[0].InstanceId' --output text )
privateIP=$( aws ec2 describe-instances --instance-ids "$instance"  --output text --query 'Reservations[0].Instances[0].PrivateIpAddress' )
publicIP=$( aws ec2 describe-instances --instance-ids "$instance"  --output text --query 'Reservations[0].Instances[0].PublicIpAddress' )
echo "Configuring instance: $instance"
echo "Private IP: $privateIP"
echo "Public IP: $publicIP"
echo "...waiting the instance to boot"

cycles=0
while true
do
	sleep 10
	instance_state=$( aws ec2 describe-instances --instance-ids "$instance" --query "Reservations[0].Instances[0].State.Name" --output text)
	[[ $instance_state == "running" ]] && break
	echo "...waiting 10s more" 
	(( cycles++ ))
	[[ $cycles -gt 10 ]] && { echo "Instance failed to boot in a reasonable time"; exit 1; } 
done

#make sure ansible can run, seems there is a slight delay until the instance can accept ssh connections and run commands
echo "Testing if ansible can ping the server"
while true
do
	sleep 10
	ansible -m ping  -i $publicIP, --user=ubuntu --private-key=$KEY.pem --ssh-extra-args='-o StrictHostKeyChecking=no' all &> /dev/null
	[[ $? -eq 0 ]] && break
	echo "...ansible ping failed, waiting 10s more"
done

echo "Running the main ansible playbook..."
sleep 1
echo "Debug: ansible-playbook -i $publicIP, --user=ubuntu --private-key=$KEY.pem --ssh-extra-args='-o StrictHostKeyChecking=no'  playbook.yaml"
ansible-playbook -i $publicIP, --user=ubuntu --private-key=$KEY.pem --ssh-extra-args='-o StrictHostKeyChecking=no'  playbook.yaml

#fingers crossed
echo "Testing the service with: curl $publicIP:8000"
echo '(drums in the background )'
echo ""
sleep 2
curl $publicIP:8000
