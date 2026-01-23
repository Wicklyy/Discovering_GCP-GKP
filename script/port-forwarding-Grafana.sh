#!/bin/bash

kubectl port-forward deployment/grafana 3000:3000 -n monitoring
