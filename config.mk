stack_name ?= ami-builder
region ?= us-east-1
packer_username ?= packer
subnet_id ?= subnet-0c071568
vpc_id ?= vpc-d1008aaa

AWS = aws --region $(region)
EC2 = $(AWS) ec2
CF = $(AWS) cloudformation
