#!/bin/bash 

# in order to make the scrip re-runnable with clean output, redirect the stderr of the init commands to a temp file. these commands need to run one time only
echo "Creating security group and ssh key"
{
	aws ec2 create-security-group --group-name flask-group-gmarik --description "security group for flask" > /dev/null || echo "Security group exists, continuing" 
	aws ec2 authorize-security-group-ingress --group-name flask-group-gmarik --protocol tcp --port 22 --cidr 0.0.0.0/0 
	aws ec2 authorize-security-group-ingress --group-name flask-group-gmarik --protocol tcp --port 8000 --cidr 0.0.0.0/0

	aws ec2 describe-key-pairs --key-names 'flask-key-gmarik' &> /dev/null && echo "ssh key exists, continuing"
	if [[ $? -ne 0 ]] 
	then
		aws ec2 create-key-pair --key-name flask-key-gmarik --query 'KeyMaterial' --output text > flask-key-gmarik.pem 
		chmod 400 flask-key-gmarik.pem
	fi
} 2>/tmp/error_log

instance=$( aws ec2 run-instances --image-id ami-9abea4fb --security-groups flask-group-gmarik --count 1 --instance-type t2.micro --key-name flask-key-gmarik  --query 'Instances[0].InstanceId' --output text )
privateIP=$( aws ec2 describe-instances --instance-ids "$instance"  --output text --query 'Reservations[0].Instances[0].PrivateIpAddress' )
publicIP=$( aws ec2 describe-instances --instance-ids "$instance"  --output text --query 'Reservations[0].Instances[0].PublicIpAddress' )

echo "Starting..."
echo "Configuring instance: $instance"
echo "Private IP: $privateIP"
echo "Public IP: $publicIP"
echo "...waiting the instance to boot"

cycles=0
while /bin/true 
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
while /bin/true
do
	sleep 20
	ansible -m ping  -i $publicIP, --user=ubuntu --private-key=flask-key-gmarik.pem --ssh-extra-args='-o StrictHostKeyChecking=no' all &> /dev/null
	[[ $? -eq 0 ]] && break
	echo "...ansible ping failed, waiting 20s more"
done

echo "Running the main ansible playbook..."
sleep 1
echo "Debug: ansible-playbook -i $publicIP, --user=ubuntu --private-key=flask-key-gmarik.pem --ssh-extra-args='-o StrictHostKeyChecking=no'  playbook.yaml"
ansible-playbook -i $publicIP, --user=ubuntu --private-key=flask-key-gmarik.pem --ssh-extra-args='-o StrictHostKeyChecking=no'  playbook.yaml

#fingers crossed
echo "Testing the service with: curl $publicIP:8000"
sleep 1
curl $publicIP:8000
