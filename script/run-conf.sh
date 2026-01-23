#!/bin/bash

source ./env.sh

echo "Creating cluster $CLUSTER_NAME in $ZONE..."

# Create the cluster in Standard Mode
gcloud container clusters create $CLUSTER_NAME \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --num-nodes=${NODE_NUMBER} \
  #--machine-type=e2-standard-2

# To resize cluster:
# gcloud container clusters resize <CLUSTER_NAME> \
#     --num-nodes <TOTAL_NUMBER_OF_NODES> \
#     --zone <YOUR_ZONE>

# gcloud container clusters resize online-boutique --num-nodes 4 --zone europe-west6-a