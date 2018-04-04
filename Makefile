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
		target=amazon-linux

ubuntu-trusty:
	$(MAKE) build \
		ami_name=hvm/ubuntu/trusty \
		ssh_username=ubuntu \
		source_ami=ami-3073884d \
		target=debian

ubuntu-xenial:
	$(MAKE) build \
		ami_name=hvm/ubuntu/xenial \
		ssh_username=ubuntu \
		source_ami=ami-b46295c9 \
		target=debian

debian-jessie:
	$(MAKE) build \
		ami_name=hvm/debian/jessie \
		ssh_username=admin \
		source_ami=ami-cb4b94dd \
		target=debian

debian-stretch:
	$(MAKE) build \
		ami_name=hvm/debian/stretch \
		ssh_username=admin \
		source_ami=ami-22be575f \
		target=debian

build:
	packer build \
		-var "ami_name=$(ami_name) $(ami_version)" \
		-var "ami_version=$(ami_version)" \
		-var "source_ami=$(source_ami)" \
		-var "ssh_username=$(ssh_username)" \
		-var "subnet_id=$(subnet_id)" \
		-var "vpc_id=$(vpc_id)" \
		-var "target=$(target)" \
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

spot_price ?= 0.0115
instance_type ?= t2.micro
keypair ?= vtse.id_rsa.pub
sg_id ?= sg-07ce9171
az ?= us-east-1a
launch-spot:
	$(EC2) request-spot-instances \
		--spot-price $(spot_price) \
		--instance-count 1 \
		--type one-time \
		--launch-specification '{"ImageId":"$(ami_id)","KeyName":"$(keypair)","InstanceType":"$(instance_type)","Placement":{"AvailabilityZone":"$(az)"},"IamInstanceProfile":{"Name":"SshReadIam"},"NetworkInterfaces":[{"DeviceIndex":0,"SubnetId":"$(subnet_id)","Groups":["$(sg_id)"],"AssociatePublicIpAddress":true}]}'

describe-spot:
	$(eval instance_id := $(shell $(EC2) describe-spot-instance-requests --spot-instance-request-ids $(request_id) --query SpotInstanceRequests[0].InstanceId --output text))
	$(EC2) describe-instances --instance-ids $(instance_id)

cancel-spot:
	$(eval instance_id := $(shell $(EC2) describe-spot-instance-requests --spot-instance-request-ids $(request_id) --query SpotInstanceRequests[0].InstanceId --output text))
	$(EC2) cancel-spot-instance-requests --spot-instance-request-ids $(request_id)
	$(EC2) terminate-instances --instance-ids $(instance_id)
