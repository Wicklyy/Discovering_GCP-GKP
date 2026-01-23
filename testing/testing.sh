#!/bin/bash

source ./setup.sh

export L_USERS=5000
export S_RATE=500

ansible-playbook -i distributed_hosts.ini distributed_loadgen.yaml

echo "Testing in progress... sleeping for 4m"
sleep 240


ansible-playbook -i distributed_hosts.ini collect_results.yaml


ansible-playbook -i hosts.ini cleanup_loadgen.yaml