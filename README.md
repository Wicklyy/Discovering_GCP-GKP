# Discovering GCP & GKP
This repo is a lab assignmenet in the context of cloud computing course aiming in applying all the theory learned during the courses in a practical enviroment such as google cloud using the kubernetees tool. It contains the full automation suite for the Online Boutique application, including GKE orchestration, Terraform provisioning, and Ansible configuration.

## Project Organization & Deployment Guide

### 1. File Map
Where to find the code for each lab step:

* **GKE Cluster Configuration:** `./script` (`env.sh`, `run-conf.sh`,`stop-conf.sh`)
* **Infrastructure as Code (VMs):** `./testing/` contains the HCL files for GCE provisioning
* **Automation Scripts:** `./script/` contains the logic for `vm_allocation`/`vm_deallocation.sh`, `loadgen.sh` and `deploy.sh`/`delete-deployment.sh`
* **Monitoring Stack:** `./microservices-demo/kustomization/monitoring/` contains the Kustomize layers for Prometheus and Grafana
* **Canary Deployment:** `./microservices-demo/kustomization/canary/`.
* **Centralized Config:** `./testing/setup.sh` is the "Source of Truth" for shared environment variables.

---

### 2. Deployment Instructions

Follow these steps in order to deploy the complete architecture:

#### GKE & Application
**1.  Configure Environment:** Edit `env.sh` with your Project ID and Region.
**2.  Provision Cluster:** 
```bash
    ./script/run-conf.sh
```
**3.  Deploy Boutique:** 
```bash
    ./script/deploy.sh
```
*note: Monitoring Stack automatically deployed in the kustomization manifest*
**4. Stop deployment:**
```bash
    ./script/delete-deployment.sh
```
**5. Free Cluster:**
```bash
    ./script/stop-conf.sh
```


#### External Load Generator
**1. Allocate Resources:**
```bash
./script/vm_allocation
```
*This runs Terraform and dynamically updates the hosts.ini with the VM's public IP.*

**2. Configure (./testing/setup.sh) and Launch:**
- classic Loadgen (no master, all vm independant):
```bash
./script/loadgen.sh
```
- distributed (master/worker configuration):
```bash
./script/distributed_loadgen.sh
```
**3. Retreive data (only if distributed):**
```bash
./script/retreive-csv.sh
```
**4. Deallocate vm's:**
```bash
./script/vm-deallocation.sh
```


## Notes
- Curently using the e2-medium instances, might have to upgrade later as they only have 4GB of RAM
- To access frontend in a browser use the outputed ip of this command:
    kubectl get service frontend-external | awk '{print $4}'
- If we deploy the project using -f kubernetes-manifests this will just apply all the files exactly as written. On the other hand the Kustomize Base follows a "Base and Overlay" pattern.

## Journal
### Configuration:
running the start up script run-conf.sh to host project on GCP (must manually change variable names if needed in env.sh)
    `./script/run-conf.sh`

### Reconfiguring the application
Using the kustomize tool we are able to reduce the CPU usage.
The first step will be to disable the loadgenerator using this command:
`kustomize edit add component components/without-loadgenerator`
This will update the `kustomize/kustomization.yaml`. If we apply this new configuration using `kubectl apply -k .`
The loadgenerator will still be active since we didnt delete the previous running pod, we then just have to manually delete it: `kubectl delete deployment loadgenerator`

### Deploying automatically a VM
After deploying the vm's using terraform using `./script/vm-allocation.sh` run the wanted Ansible script for testing `./script/loadgen.sh`
The first script will launch terraform and create the wanted specifications in the `testing/setup.sh` file and saves all the vm's ip in the `testing/hosts` file. Once that done that ansible will deploy the wanted script on those VM. 

### Monitoring the application and the infrastructure
To monitor my GKE cluster, I deployed Prometheus for data collection and Grafana for visualization. Since Prometheus can't access hardware directly, I used Node Exporter (a DaemonSet) to pull node-level stats (CPU/RAM), while cAdvisor (native to GKE) provided container-level metrics for the Online Boutique services. I authorized these connections via RBAC (ServiceAccount and ClusterRole) and configured the scraping logic in prometheus-config.yaml. Finally, I connected Grafana to Prometheus using its internal cluster URL (http://prometheus:9090), imported community dashboards, and adjusted the Variables and Legends so that the "Live Data" correctly identifies specific microservices like frontend or redis instead of generic container names.
Quick commands:
* **Check node-exporter targets:** `kubectl get svc node-exporter -n monitoring`
* **Access UI:** `kubectl get svc grafana -n monitoring`

Configuring dashboard id's:
| Target | Dashboard ID | 
|---|---|
| Nodes | 1860|
| Pods | 315 |
| Redis | 763 |
| gRPC | 14765|

After alot of time wasted trying to correct the imported dashboards (many sections were not working, no data retrieved due to missmatching names), I found it much easier to create my own. The Grafana dashboard "Custom Dashboard" showcases all what I needed for my report.
 


### Canary releasse
create the `productcatalog-v2.yaml` file.
kubectl apply -f productcatalog-v2.yaml
kubectl scale deployment productcatalogservice --replicas=3
kubectl scale deployment productcatalogservice-v2 --replicas=3
kubectl scale deployment productcatalogservice --replicas=0

To achieve a zero-downtime transition, the v2 deployment was scaled up first. Once the new pods passed their readiness probes, the v1 deployment was scaled to zero. This ensured the Service always had active endpoints, preventing any disruption to in-flight requests

Version v2 Change: "Modified the ProductCatalog deployment environment variables to include an EXTRA_LATENCY of 100ms, simulating a logic change in the service."

Traffic Split: "Utilized Kubernetes native load balancing by controlling the ratio of pod replicas (3:1) to achieve a 25% Canary weight."

Validation: "Used kubectl logs and Grafana pod-level metrics to confirm the traffic distribution."


for the rollback what we did is monitor the cpu usage time for the two version of service and we saw that the v3 was always idling and wasnt producing work, with this observation we must rollback to the previous version by deleting the existing v3 pod:
kubectl delete deployment productcatalogservice-v3