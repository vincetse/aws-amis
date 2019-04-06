stack_name ?= ami-builder
region ?= us-east-1
packer_username ?= packer
subnet_id ?= subnet-05cff71054d7d97fa
vpc_id ?= vpc-0e9dcb43eec1aa096

AWS = aws --region $(region)
EC2 = $(AWS) ec2
CF = $(AWS) cloudformation
