#!/bin/bash

echo "running terraform"
terraform init
terraform validate
terraform apply -auto-approve
terraform destroy -auto-approve
aws sts get-caller-identity
