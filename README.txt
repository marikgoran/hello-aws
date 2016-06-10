Small script to automate deployment of flask apps on a EC2 instance.

Dependencies:
- bash 4+
- fully configured aws cli, tested with the AWS free tier
- ansible 2+
Tested and developed on OSX 10.9 and Ubuntu 16.04

Usage:
- clone the repo
- run ./hello.sh

Notes:
  The hello.sh script will create the EC2 ssh key in the current working directory, create a security group in EC2 and launch a ubuntu 14.04 t2.micro instance.
  Once the instance is booted, it will run the playbook.yaml against it with ansible-playbook. 
  The playbook with configure the instance with gunicorn and deploy a small flask app on port 8000. 
  
Bugs and errors:
  * The deployment script will not terminate the instance. Make sure to terminate it manually *
  You can run the script as many time as needed, but on each run a new EC2 instance will be deployed. 
  
  
