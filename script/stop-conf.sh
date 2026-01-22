#!/bin/bash

source ./env.sh

echo "Deleting cluster $CLUSTER_NAME in $ZONE..."

gcloud container clusters delete online-boutique \
  --project=${PROJECT_ID} --zone=${ZONE}