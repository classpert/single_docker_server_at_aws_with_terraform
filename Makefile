include keys/env

REMOTE_DOMAIN ?= docker.remote
REMOTE_IP ?= $(shell $(TERRAFORM) output docker_server_ip)

TERRAFORM := ./bin/terraform
PLAN_PATH := plans/docker.plan

INSTANCE_ID := $(shell $(TERRAFORM) output docker_instance_id)

EMAIL ?= your_email@example.com

SSH_KEY := keys/developer_rsa

AWS_CREDENTIALS := AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY)

STATUS_CMD := $(AWS_CREDENTIALS) aws ec2 describe-instance-status --region $(AWS_DEFAULT_REGION) --instance-ids $(INSTANCE_ID)

default: plan

configure: ./keys/developer_rsa ./keys/ca-key.pem ./keys/user-key.pem

plan: configure
	@$(TERRAFORM) plan -out $(PLAN_PATH)

apply: configure
	@$(TERRAFORM) apply $(PLAN_PATH)

destroy:
	@$(TERRAFORM) destroy

refresh:
	@$(TERRAFORM) refresh
	@echo "Remember to reconfigure references to public ip address"

show_ip:
	@echo $(REMOTE_IP)

instance_id:
	@echo $(INSTANCE_ID)

status:
	@$(STATUS_CMD)

start:
	@echo "Starting Instance..."
	@$(AWS_CREDENTIALS) aws ec2 start-instances --region $(AWS_DEFAULT_REGION) --instance-ids $(INSTANCE_ID)
	@make -s wait_instance
	@make -s refresh

stop:
	@echo "Stopping Instance..."
	@$(AWS_CREDENTIALS) aws ec2 stop-instances --region $(AWS_DEFAULT_REGION) --instance-ids $(INSTANCE_ID)

wait_instance:
	@until [ `sh -c "$(STATUS_CMD) | jq -r '.InstanceStatuses[0].SystemStatus.Status'"` = "ok" ]; do sleep 3; echo "Waiting for instance..."; done;

ca_credentials:
	@./bin/create_ca_credentials $(REMOTE_DOMAIN)

server_credentials:
	@./bin/create_server_credentials $(REMOTE_DOMAIN) $(REMOTE_IP)

user_credentials:
	@./bin/create_user_credentials $(REMOTE_DOMAIN)

./keys/developer_rsa:
	@ssh-keygen -b 4096 -f $(SSH_KEY) -C '$(EMAIL)'

./keys/ca-key.pem:
	@make -s ca_credentials

./keys/server-key.pem:
	@make -s server_credentials

./keys/user-key.pem:
	@make -s user_credentials

.PHONY: configure plan apply destroy refresh show_ip instance_id status start stop ca_credentials server_credentials user_credentials
