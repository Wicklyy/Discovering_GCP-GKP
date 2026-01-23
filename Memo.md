# ☁️ GCloud & Kubernetes Cheat Sheet

A quick reference guide for Google Cloud Platform and GKE cluster management.

---

## 🛠 Google Cloud Configuration

### Project Management
| Command | Description |
| :--- | :--- |
| `gcloud projects list` | List all available projects |
| `gcloud config set project [PROJECT_ID]` | Set the active project |
| `gcloud config list` | Show current configuration and project info |

### Zones & Connection
| Command | Description |
| :--- | :--- |
| `gcloud compute zones list` | List all available GCP zones |
| `gcloud config set compute/zone [ZONE]` | Set default zone (e.g., `europe-west6-a`) |
| `gcloud compute ssh [NODE_ID]` | SSH into a specific Compute Engine node |

---

## 🏗 GKE Cluster Management

| Command | Description |
| :--- | :--- |
| `gcloud container clusters create [NAME]` | Create a new GKE cluster |
| `gcloud container clusters get-credentials [NAME]` | Authenticate `kubectl` with your cluster |
| `gcloud container clusters delete [NAME]` | Delete the specified cluster |

---

## ☸️ Kubectl Operations

### Nodes & Cluster State
* **List Nodes:** `kubectl get nodes`
* **Node Details:** `kubectl describe nodes [NODE_ID]`
* **All Namespaces:** `kubectl get pods --all-namespaces` (View system + user pods)

### Pods
* **Deploy Pod:** `kubectl create deployment [NAME] --image=[DOCKER_IMAGE]`
* **List Pods:** `kubectl get pods`
* **Describe Pod:** `kubectl describe pods [POD_ID]`
* **Run Temporary Pod:** `kubectl run -i --rm --restart=Never [NAME] --image=[IMAGE] -- [FLAGS]`
* **Delete Pod:** `kubectl delete pod [POD_ID]`

### Deployments & Scaling
* **List Deployments:** `kubectl get deployments`
* **Describe Deployment:** `kubectl describe deployments [NAME]`
* **Apply YAML:** `kubectl apply -f <directory_or_file>`
* **Manual Scale:** `kubectl scale deployment [NAME] --replicas=[NUMBER]`
* **Autoscale:** `kubectl autoscale deployment [NAME] --cpu-percent=60 --min=2 --max=5`

---

## 🔍 Troubleshooting & Debugging



| Command | Description |
| :--- | :--- |
| `kubectl logs [POD_ID]` | View standard output logs from a pod |
| `kubectl logs -f [POD_ID]` | Stream/Follow logs in real-time |
| `kubectl exec -it [POD_ID] -- bin/bash` | Open an interactive shell inside a running pod |
| `kubectl top pod` | Show CPU and Memory usage for pods |
| `kubectl get events --sort-by='.lastTimestamp'` | View cluster events (useful for finding crash causes) |

---

## 🌐 Networking & Services

### Service Management
| Command | Description |
| :--- | :--- |
| `kubectl get svc -n [Scope]` | List all active services in a scope and their IPs, if no scope defined `default` scope is set |
| `kubectl describe svc [SERVICE_NAME]` | Detailed information about a service |
| `kubectl expose deployment [NAME] --port [SVC_PORT] --target-port [POD_PORT] --type LoadBalancer` | Create an external Load Balancer |

### Firewall Rules (GCloud)
Use these to manage external access at the network level.

**Create Firewall Rule:**
```bash
gcloud compute firewall-rules create default-allow-[PORT] \
    --project=[PROJECT_ID] \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:[PORT] \
    --source-ranges=0.0.0.0/0
```
***Delete Firewall Rule:**
```bash
gcloud compute firewall-rules delete default-allow-[PORT] --project=[PROJECT_ID]
```

# Terraform and Ansible
## Terraform
* **Initialize a new or existing Terraform working directory**: `terraform init`
* **Review the state that is going to be created**: `terraform plan`
* **Launch/Update the deployment**: `terraform apply`
* **Deallocate ressources**: `terraform destroy`

## Ansible
* **run script**: ansible-playbook -i [host(s)] [script.yml]
* **download pkg**: ansible-galaxy collection install [pkg name]