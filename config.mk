stack_name ?= ami-builder
region ?= us-east-1
packer_username ?= packer
subnet_id ?= subnet-078533e137291e536
vpc_id ?= vpc-0d73667c1af7d7807

AWS = aws --region $(region)
EC2 = $(AWS) ec2
CF = $(AWS) cloudformation
