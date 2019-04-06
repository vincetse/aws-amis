include config.mk
ami_version ?= $(shell date -u +%Y%m%d.%H%M)

all: amazon-linux ubuntu-trusty ubuntu-xenial debian-jessie debian-stretch

amazon-linux:
	$(MAKE) build \
		ami_name=hvm/amazon-linux/2018.03.0.20181129 \
		ssh_username=ec2-user \
		source_ami=ami-0f78717cb15ab06bd \
		target=amazon-linux

ubuntu-xenial:
	$(MAKE) build \
		ami_name=hvm/ubuntu/xenial \
		ssh_username=ubuntu \
		source_ami=ami-092d0d014b7b31a08 \
		target=debian

ubuntu-bionic:
	$(MAKE) build \
		ami_name=hvm/ubuntu/bionic \
		ssh_username=ubuntu \
		source_ami=ami-07e101c2aebc37691 \
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
		source_ami=ami-0bd9223868b4778d7 \
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
