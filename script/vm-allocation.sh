#!/bin/bash

cd ../testing

source ./setup.sh

echo "Launching VM's using Terraform"
terraform apply


echo "Extracting VM's ip in host file"
./parse-tf-state.py