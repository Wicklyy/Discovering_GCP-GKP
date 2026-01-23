#!/bin/bash

echo "Moving to testing folder"
cd ../testing

source ./setup.sh

echo "running ansible loadgen script"
ansible-playbook -i hosts.ini deploy_loadgen.yml

#to stop spam
#ansible all -i hosts.ini -m shell -a "sudo docker stop loadgen"