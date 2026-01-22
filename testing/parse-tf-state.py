#!/usr/bin/env python3

import json
import sys
import os

IPs = []

# Load the Terraform state
with open('terraform.tfstate') as json_file:
    data = json.load(json_file)
    for res in data['resources']:
        # Matches the resource name in your simple_deployment.tf
        if res['name'] == 'vm_instance':
            for vm in res['instances']:
                for nic in vm['attributes']['network_interface']:
                    ip = nic['access_config'][0]['nat_ip']
                    IPs.append(ip)
                    print(f"Found VM: {vm['attributes']['name']} (IP: {ip})")

# Write the Ansible inventory
with open('hosts', 'w') as host_file:
    host_file.write('[loadgenerators]\n')
    for IP in IPs:
        host_file.write(IP + '\n')
    
    host_file.write('\n[all:vars]\n')
    # Uses the variables you exported in setup.sh
    host_file.write('ansible_ssh_user={}\n'.format(os.environ['GCP_userID']))
    host_file.write('ansible_ssh_private_key_file={}\n'.format(os.environ['GCP_privateKeyFile']))
    host_file.write('ansible_ssh_common_args=\'-o StrictHostKeyChecking=no\'\n')