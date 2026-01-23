#!/bin/bash


### Main variables

# User ID on GCP
export GCP_userID="ryanro2001_gmail_com"

# Private key to use to connect to GCP
export GCP_privateKeyFile="~/.ssh/google_compute_engine"

# Name of your GCP project
export TF_VAR_project="model-arcadia-478207-j1"

# Name of your selected GCP region
export TF_VAR_region="europe-west6"

# Name of your selected GCP zone
export TF_VAR_zone="europe-west6-a"

# Fetch the public ip of the frontend
export FRONTEND_IP=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

### Other variables used by Terrform

# Number of VMs created
export TF_VAR_machineCount=3

# VM type
export TF_VAR_machineType="f1-micro"

# Prefix for you VM instances
export TF_VAR_instanceName="tf-instance"

# Prefix of your GCP deployment key
export TF_VAR_deployKeyName="testing-key.json"

