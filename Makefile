stack_name ?= ami-builder
region ?= us-east-1
template ?= iam.yml
packer_username ?= packer
subnet_id ?= subnet-0c071568
vpc_id ?= vpc-d1008aaa
ami_version ?= $(shell date -u +%Y%m%d.%H%M)

AWS = aws --region $(region)
EC2 = $(AWS) ec2

all: amazon-linux ubuntu-trusty ubuntu-xenial debian-jessie debian-stretch

amazon-linux:
	$(MAKE) build \
		ami_name=hvm/amazon-linux/2017.09.1 \
		ssh_username=ec2-user \
		source_ami=ami-1853ac65 \
		user_data_file=user-data/$@.txt

ubuntu-trusty:
	$(MAKE) build \
		ami_name=hvm/ubuntu/trusty \
		ssh_username=ubuntu \
		source_ami=ami-3073884d \
		user_data_file=user-data/$@.txt

ubuntu-xenial:
	$(MAKE) build \
		ami_name=hvm/ubuntu/xenial \
		ssh_username=ubuntu \
		source_ami=ami-b46295c9 \
		user_data_file=user-data/$@.txt

debian-jessie:
	$(MAKE) build \
		ami_name=hvm/debian/jessie \
		ssh_username=admin \
		source_ami=ami-cb4b94dd \
		user_data_file=user-data/$@.txt

debian-stretch:
	$(MAKE) build \
		ami_name=hvm/debian/stretch \
		ssh_username=admin \
		source_ami=ami-22be575f \
		user_data_file=user-data/$@.txt

build:
	packer build \
		-var "ami_name=$(ami_name) $(ami_version)" \
		-var "ami_version=$(ami_version)" \
		-var "source_ami=$(source_ami)" \
		-var "ssh_username=$(ssh_username)" \
		-var "subnet_id=$(subnet_id)" \
		-var "vpc_id=$(vpc_id)" \
		-var "user_data_file=$(user_data_file)" \
		packer.json

list:
	$(eval account_id := $(shell aws sts get-caller-identity --output text --query 'Account'))
	$(EC2) describe-images --filters Name=owner-id,Values=$(account_id)
	$(EC2) describe-snapshots --filters Name=owner-id,Values=$(account_id)

deregister-image:
	$(EC2) $@ --image-id $(ami)

delete-snapshot:
	$(EC2) $@ --snapshot-id $(snapshot)

delete-all:
	$(eval account_id := $(shell aws sts get-caller-identity --output text --query 'Account'))
	$(eval amis := $(shell $(EC2) --output text describe-images --filters Name=owner-id,Values=$(account_id) --query 'Images[].ImageId'))
	@for ami in $(amis); do \
		$(MAKE) deregister-image ami=$${ami}; \
	done
	$(eval snapshots := $(shell $(EC2) --output text describe-snapshots --filters Name=owner-id,Values=$(account_id) --query 'Snapshots[].SnapshotId'))
	@for snapshot in $(snapshots); do \
		$(MAKE) delete-snapshot snapshot=$${snapshot}; \
	done
