#!/bin/bash

source ./env.sh

echo "Creating cluster $CLUSTER_NAME in $ZONE..."

# Create the cluster in Standard Mode
gcloud container clusters create $CLUSTER_NAME \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  #--num-nodes=3 \
  #--machine-type=e2-standard-2