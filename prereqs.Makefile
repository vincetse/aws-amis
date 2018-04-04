include config.mk
template ?= prereqs.yml

TEMPLATE = --template-body file://$(template)
STACK = --stack-name $(stack_name)

validate:
	$(CF) validate-template $(TEMPLATE)

create update: validate
	$(CF) $@-stack $(STACK) $(TEMPLATE) \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			ParameterKey=PackerUserName,ParameterValue=$(packer_username)
	$(CF) wait stack-$@-complete $(STACK)

delete:
	$(CF) $@-stack $(STACK)
	$(CF) wait stack-$@-complete $(STACK)

describe:
	$(CF) $@-stacks $(STACK)
