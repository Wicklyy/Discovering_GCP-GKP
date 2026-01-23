#!/bin/bash

cd ../testing

source ./setup.sh

echo "Launching VM's using Terraform"
terraform apply -auto-approve


echo "Extracting VM's ip in host file"
./parse-tf-state.py
./distributed-parse-tf-state.py