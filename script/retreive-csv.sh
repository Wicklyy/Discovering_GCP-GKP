#!/bin/bash

cd ../testing

ansible-playbook -i distributed_hosts.ini collect_results.yaml