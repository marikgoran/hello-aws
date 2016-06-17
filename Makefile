publicIP=$(shell terraform output | awk '/publicIP/ {print $$3}' )

help:
	@printf 'Usage:\n Run "make prep" once to create the keys and groups\n Run "make instance" to create the instance with terraform\n Run "make info" to get the IP addresses of the instance\n Run "make deploy" to configure the instance with ansible - give some to the instance to boot first\n Run "make hello" to test it all\n'

prep:
	@-aws ec2 create-key-pair --key-name terraform --query 'KeyMaterial' --output text > terraform.pem
	@chmod 400 terraform.pem
	@-aws ec2 create-security-group --group-name terraform --description "security group for flask with terraform";
	@-aws ec2 authorize-security-group-ingress --group-name terraform --protocol tcp --port 22 --cidr 0.0.0.0/0
	@-aws ec2 authorize-security-group-ingress --group-name terraform --protocol tcp --port 8000 --cidr 0.0.0.0/0

instance:
	@terraform plan
	@terraform apply

deploy:
	ansible-playbook -i $(publicIP), --user=ubuntu --private-key=terraform.pem --ssh-extra-args='-o StrictHostKeyChecking=no'  playbook.yaml
	
#it seems terraform cannot create ad-hoc keys, so wrap the prep steps with undo target for easier testing
unprep:
	@echo yes | terraform destroy
	@aws ec2 delete-security-group --group-name 'terraform' || true
	@aws ec2 delete-key-pair --key-name 'terraform' || true
	@rm -f terraform.pem 

#target to test ssh access to the instance
test-ssh:
	ssh -i terraform.pem -o StrictHostKeyChecking=no ubuntu@$(publicIP) uptime
	
hello:
	curl $(publicIP):8000 
	
info:
	@terraform output
