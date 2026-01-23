#!/usr/bin/env python3

import json
import sys
import os

# Storage for VM metadata
vms = []

# 1. Load the Terraform state
if not os.path.exists('terraform.tfstate'):
    print("Error: terraform.tfstate not found. Ensure you have run 'terraform apply'.")
    sys.exit(1)

with open('terraform.tfstate') as json_file:
    try:
        data = json.load(json_file)
        for res in data['resources']:
            # Matches the resource name in your simple_deployment.tf
            if res['name'] == 'vm_instance':
                for vm in res['instances']:
                    attributes = vm['attributes']
                    name = attributes['name']
                    # Get the internal (private) IP
                    priv_ip = attributes['network_interface'][0]['network_ip']
                    # Get the external (public) IP
                    pub_ip = attributes['network_interface'][0]['access_config'][0]['nat_ip']
                    
                    vms.append({
                        'name': name,
                        'public_ip': pub_ip,
                        'private_ip': priv_ip
                    })
                    print(f"Found VM: {name} | Public: {pub_ip} | Private: {priv_ip}")
    except (KeyError, IndexError) as e:
        print(f"Error parsing terraform.tfstate: {e}")
        sys.exit(1)

if not vms:
    print("No VM instances found in the state file.")
    sys.exit(1)

# 2. Assign Master and Workers
# We take the first VM as the master
master = vms[0]
workers = vms[1:]

# 3. Write the Ansible inventory (hosts.ini)
with open('distributed_hosts.ini', 'w') as host_file:
    # Master Group
    host_file.write('[loadgen_master]\n')
    # We store the private_ip as a variable so Ansible can pass it to the workers
    host_file.write(f"{master['public_ip']} private_ip={master['private_ip']}\n\n")
    
    # Workers Group
    host_file.write('[loadgen_workers]\n')
    for worker in workers:
        host_file.write(f"{worker['public_ip']} private_ip={worker['private_ip']}\n")
    
    if not workers:
        print("Warning: Only 1 VM found. Running in Master-only mode (No workers).")

    # Global variables for SSH access
    host_file.write('\n[all:vars]\n')
    host_file.write('ansible_ssh_user={}\n'.format(os.environ.get('GCP_userID', 'user')))
    host_file.write('ansible_ssh_private_key_file={}\n'.format(os.environ.get('GCP_privateKeyFile', '~/.ssh/id_rsa')))
    host_file.write('ansible_ssh_common_args=\'-o StrictHostKeyChecking=no\'\n')

print(f"\nSuccessfully generated hosts.ini")
print(f"Master: {master['public_ip']} (Internal: {master['private_ip']})")
print(f"Workers: {len(workers)}")