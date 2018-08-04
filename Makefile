include config.mk
ami_version ?= $(shell date -u +%Y%m%d.%H%M)

all: amazon-linux ubuntu-trusty ubuntu-xenial debian-jessie debian-stretch

amazon-linux:
	$(MAKE) build \
		ami_name=hvm/amazon-linux/2018.03.0.20180622 \
		ssh_username=ec2-user \
		source_ami=ami-f316478c \
		target=amazon-linux

ubuntu-trusty:
	$(MAKE) build \
		ami_name=hvm/ubuntu/trusty \
		ssh_username=ubuntu \
		source_ami=ami-817bf7fe \
		target=debian

ubuntu-xenial:
	$(MAKE) build \
		ami_name=hvm/ubuntu/xenial \
		ssh_username=ubuntu \
		source_ami=ami-077b0e78 \
		target=debian

ubuntu-bionic:
	$(MAKE) build \
		ami_name=hvm/ubuntu/bionic \
		ssh_username=ubuntu \
		source_ami=ami-6061141f \
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
		source_ami=ami-b592abca \
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

delete-key-pair:
	$(EC2) $@ --key-name $(keyname)

delete-security-group:
	$(EC2) $@ --group-id $(sgid)

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
	$(eval keypairs := $(shell $(EC2) --output text describe-key-pairs --query "KeyPairs[?starts_with(KeyName,'packer_')].KeyName"))
	@for keypair in $(keypairs); do \
		$(MAKE) delete-key-pair keyname=$${keypair}; \
	done
	$(eval sgids := $(shell $(EC2) --output text describe-security-groups --query "SecurityGroups[?starts_with(GroupName, 'packer_')].GroupId"))
	@for sgid in $(sgids); do \
		$(MAKE) delete-security-group sgid=$${sgid}; \
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
