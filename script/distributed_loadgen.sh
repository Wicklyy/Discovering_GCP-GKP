#!/bin/bash

echo "Moving to testing folder"
cd ../testing

source ./setup.sh

echo "running ansible distributed loadgen script"
ansible-playbook -i distributed_hosts.ini distributed_loadgen.yml

#to stop spam
#ansible all -i hosts.ini -m shell -a "sudo docker stop loadgen-master"
#ansible all -i hosts.ini -m shell -a "sudo docker stop loadgen-worker"
