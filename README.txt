# hello-aws
Small script to deploy flask app on AWS, with terraform, ansible and makefiles.

Dependencies:
- bash 4+
- fully configured aws cli, tested with the AWS free tier
- ansible 2+
- terraform v0.6.16
- make or gmake
Tested and developed on OSX 10.9 with up to date homebrew and Ubuntu 16.04 with default repos.

Description:
  The script is driven by make, in order to provide consistent user/ops experience. It seems that terraform in the current version does not support creating keys for AWS, so some interaction to awscli would have been required anyways.

The instance config is done with ansible, by reusing the code in the master branch. Migrating this part of the code to the chef provisoner would probably make more sense.

Usage:
  git clone git@github.com:marikgoran/hello-aws.git
  cd hello-aws
  git checkout terraform
  # create a file called terraform.tfvars - this file is excluded from the repo in .gitignore. 
  # the file should have the credentials in format:
  # access_key = "abc"
  # secret_key = "xyz"
  make (this will print the help page )
  make prep (create the keys and security group with awscli )
  make instance (the heavy lifting is done by terraform here, the terraform output will be the IP addresses of the instance)
  make info (shortcut for terraform output )
  make deploy (run the ansible playbook ) 
  make hello ( testing the service with curl)
  make destroy ( terraform destroy && awscli delete keys and groups )
  
  
  
