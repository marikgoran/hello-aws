Small script to automate deployment of flask apps on a EC2 instance.

Dependencies:
- Linux workstation, tested on Ubuntu 16.04
- fully configured aws cli, tested with the AWS free tier
- ansible, from the Ubuntu 16.04 repo

Usage:
- clone the repo
- run ./hello.sh

Notes:
  The hello.sh script will create the EC2 ssh key in the current working directory, create a security group in EC2 and launch a ubuntu 14.04 t2.micro instance.
  Once the instance is booted, it will run the playbook.yaml against it with anisible-playbook. 
  The playbook with configure the instance with gunicorn and deploy a small flask app on port 8000. 
  
