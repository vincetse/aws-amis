include config.mk

spot_price ?= 0.0115
instance_type ?= t2.micro
keypair ?= vtse.id_rsa.pub
sg_id ?= sg-07ce9171
az ?= us-east-1a

launch:
	$(EC2) request-spot-instances \
		--spot-price $(spot_price) \
		--instance-count 1 \
		--type one-time \
		--launch-specification '{"ImageId":"$(ami_id)","KeyName":"$(keypair)","InstanceType":"$(instance_type)","Placement":{"AvailabilityZone":"$(az)"},"IamInstanceProfile":{"Name":"SshReadIam"},"NetworkInterfaces":[{"DeviceIndex":0,"SubnetId":"$(subnet_id)","Groups":["$(sg_id)"],"AssociatePublicIpAddress":true}]}'

describe:
	$(eval instance_id := $(shell $(EC2) describe-spot-instance-requests --spot-instance-request-ids $(request_id) --query SpotInstanceRequests[0].InstanceId --output text))
	$(EC2) describe-instances --instance-ids $(instance_id)

cancel:
	$(eval instance_id := $(shell $(EC2) describe-spot-instance-requests --spot-instance-request-ids $(request_id) --query SpotInstanceRequests[0].InstanceId --output text))
	$(EC2) cancel-spot-instance-requests --spot-instance-request-ids $(request_id)
	$(EC2) terminate-instances --instance-ids $(instance_id)
