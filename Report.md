
# Cloud Computing Lab Assignment Report
**MOSIG M2**
ROUIBAH Ryan

---
## 1. Deploying the original application in GKE
### GKE configuration

To ensure a reproducible and structured deployment, I automated the environment setup using a shell script. 
I first defined the core environment variables the file [env.sh](script/env.sh). The deployment is then handled by the [run-conf.sh](script/run-conf.sh) script. This script sources the variables and utilizes the gcloud CLI to provision the GKE cluster.

### Question: GKE Autopilot vs. Standard Mode
Autopilot abstracts the hardware layer, depending on the load of the infrastructure Google would automatically add or remove ressources based on the curent needs.
Right now we are locked into 3 e2-medium nodes which are instances restricted to 4GB of RAM. If the app fails to deploy because of "Insufficient memory," we will need to manually resize our cluster. 

### Reconfiguring the application
With only 3 nodes, the ressources are insufficient to deploy all the pods displayed in the base folder. To successfully load the full deployment in these 3 nodes we did the following modifications:
- We disabled the load_generator from the deployment: This was done by adding the component `components/without-loadgenerator` in the [kustomization.yaml](microservices-demo/kustomize/kustomization.yaml) file.
- We reduced requested ressources for two services as suggested in the following question: This was done by applying a patche file to each chosen service by reducing their cpu request by 2.

### Question: Which of the two parameters (requests and limits) actually matters when Kubernetes decides that it can deploy a service on a worker node?
The requests parameter is the one that matters for deployment decisions. If there is not enough ressource requested for the service, it will not be deployed.

current ressource for each pod:
| Service | CPU |
| :--- | :--- |
| adservice | 300m |
| cartservice | 300m |
| checkoutservice.yaml | 100m |
| currencyservice | 100m |
| emailservice | 100m |
| frontend | 100m |
| loadgenerator | 300m |
| paymentservice | 100m |
| productcatalogservice | 100m |
| recommendationservice | 100m |
| shippingservice | 100m |

Based on the cpu requests of each service we chose to reduce the requested ressource for these two:
- emailservice: The email should only be sent once after the customer completed his payement and would not notice if it wasn't immediate.
- shippingservice: The shipping cost is a simple calculation done once when the client is about to proceed to the payement, this will not impact the overall experience of the user.

---

## 2. Analyzing the provided configuration: adservice.yaml

The `adservice.yaml` manifest defines the deployment, networking, and security identity for the Advertising Service. It consists of two primary resources: a Service and a Deployment.

### 1. Resource: Deployment
The Deployment manages the lifecycle and scaling of the application pods.

* **`apiVersion: apps/v1`**: Uses the stable Apps API for deployment management.
* **`kind: Deployment`**: Creates a controller that maintains the health of the pods.
* **`selector/matchLabels`**: Tells the deployment which pods to manage based on the `app: adservice` label.
* **`terminationGracePeriodSeconds: 5`**: Allows the application 5 seconds to finish active requests before the container is forcefully terminated during a shutdown.

* **`securityContext (Pod level)`**: Includes `runAsNonRoot: true` to prevent the container from starting with root privileges and `fsGroup: 1000` for consistent file system permissions.
* **`securityContext (Container level)`**: Implements `readOnlyRootFilesystem: true`, making the container's OS files immutable.

* **`image`**: Points to the specific binary image (`v0.10.4`) stored in the Google Artifact Registry.
* **`env/PORT`**: An environment variable that tells the application to listen on port 9555.
* **`resources/requests`**: The **guaranteed** CPU (200m) and Memory (180Mi) reserved on the node.
* **`resources/limits`**: The **maximum** CPU (300m) and Memory (300Mi) the pod is allowed to consume.

* **`readinessProbe`**: Uses **gRPC** to check if the app is ready to serve traffic. It waits 20 seconds for the Java VM to warm up.
* **`livenessProbe`**: Checks if the app has crashed or deadlocked. If this fails, Kubernetes restarts the container automatically.


### 2. Resource: Service
The Service provides a stable network abstraction layer.

* **`kind: Service`**: Creates a virtual IP and DNS name.
* **`type: ClusterIP`**: Ensures the service is only reachable from within the GKE cluster.
* **`selector`**: Dynamically maps the service to any pods labeled `app: adservice`.
* **`ports`**: Maps the Service port (**9555**) to the application's targetPort (**9555**).


## 3. Deploying automatically the load generator in Google Cloud
### My Approach to Automation

For this section, I moved away from the manual VM creation approach. As asked, the goal was to create a "one-button" deployment where I could spin up any number of load generators and have them immediately start stressing the application.

### Phase 1: Learning and Adapting

I followed a structured learning path to build this system:
1. Terraform Basics: I first experimented with basic Terraform providers to understand how to authenticate with GCP and reserve a single google_compute_instance. This was done following the [Provisioning VMs with Terraform](https://roparst.gricad-pages.univ-grenoble-alpes.fr/cloud-tutorials/terraform/) tutorial.
2. Hybrid Integration: I then studied the integration of Ansible and Terraform by following the given [Running MPI applications](https://roparst.gricad-pages.univ-grenoble-alpes.fr/cloud-tutorials/mpi/) tutorial.
3. Template Customization: Once I mastered the basics, I copied the provided templates into my `testing/` folder and modified the resource definitions (machine types, network tags) to suit the loadgen requirements.

### Phase 2: Implementation & Orchestration

I designed a two-step automated pipeline using custom scripts to bridge the gap between provisioning and configuration.

#### 1. Provisioning: `./script/vm_allocation`
- It runs terraform apply to reserve the GCE instances.
- A python script [parse-tf-state.py](./testing/parse-tf-state.py) is then executed to extract the newly created VM external IPs and write them directly into the [hosts.ini](./testing/hosts.ini) file.

#### 2. Configuration: `./script/loadgen.sh`

Once the hosts.ini is populated, this script triggers the Ansible playbook. I configured the playbook to perform three specific tasks:

- System Preparation: Automatically installs Docker on the fresh VM and check that it is indeed running

- Image Fetching: Pulls the loadgen Docker image from the repository.

- Deployment: Starts the container. By using Docker on the VM

### Reflection on the Approach

By separating the logic into vm_allocation (Terraform) and loadgen.sh (Ansible), I created a modular system. This modularity allows me to reuse the same provisioning logic and simply swap out the Ansible playbook if I need to run a different type of test or update the load generation parameters.

### Technical Challenges & Solutions

One of the main challenges was dynamically forwarding the Frontend External IP from the GKE cluster to the Ansible script running on the remote VM.

I solved this by creating a centralized [setup.sh](./testing/setup.sh) file. This file acts as the "source of truth" for all environment variables used by both Terraform and Ansible. To handle the dynamic IP, I used the following command within the script:
```bash
export FRONTEND_IP=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```
By sourcing `setup.sh` in all my test scripts, I ensure that the Ansible tests are always pointing to the most current frontend ip.

---
## 4. Monitoring the application and the infrastructure
### Observability Stack

I deployed a custom monitoring stack in a dedicated monitoring namespace using Prometheus for collection and Grafana for visualization.
* **Data Sources:**
    * Nodes: Tracked via Node Exporter (DaemonSet).
    * Pods: Tracked via GKE’s native cAdvisor metrics.
    * Applications: Custom scrape jobs for gRPC-annotated pods and a dedicated Redis Exporter.
    *note: I was unnable to use the scraper for grpc since I couldn't find a working image*
* **Persistence & Reliability:** 
    * I implemented a Persistent Volume Claim (PVC) for Grafana to ensure dashboards survived pod restarts.
    * I hardcoded the Prometheus data source in the Grafana configuration YAML to automate the initial connection.

### Custom Dashboards and Alerting [Bonus]

After finding that community dashboards (IDs 1860, 315, etc.) often had broken panels due to label mismatches, I built a Custom Dashboard. This allowed me to map raw container metrics to specific microservice names (like frontend or checkoutservice) accurately.

Alerting: I configured a RedisCartDown alert group in [prometheus-config.yaml](microservices-demo/kustomize/monitoring/prometheus-config.yaml) (Prometheus) to trigger a critical notification if the Redis backend or its exporter becomes unreachable for more than 30 seconds.

---

## 5. Performance evaluation
### Methodology

To conduct a realistic performance evaluation, I used my Terraform/Ansible scripts (I updated the ansible to handle the master/worker implementation) to deploy the load generator on a dedicated GCE VM in the same region as the cluster (europe-west6). This ensures that network latency between the generator and the app is minimized.

I defined five test tiers to observe the system's behavior under increasing pressure:
We will be conducting the following tests:

| Test Type | Users | RPS (Throughput) | P95 Latency | Failure Rate |
| :---: | :---: | :---: | :---: | :---: |
| Baseline | 50 | 2.15 | 98 ms | 0.19% |
| Load Test | 200 | 2.19 | 52 ms | 0.00% |
| Stress Test | 500 | 2.20 | 39 ms | 0.00% |
| Break Test | 1000 | 2.15 | 46 ms | 0.19% |
| Panic Test | 5000 | 2.14 | 40 ms | 0.00% |

### Analysis of Results

#### The "Warming Up" Effect
A counter-intuitive finding in the data is that the P95 Latency improved as the load increased (dropping from 98ms at baseline to ~40ms during stress). This indicates a significant "cache warming" effect: as the initial tests ran, Redis and internal application caches became populated, and JIT optimizations likely kicked in, leading to faster subsequent response times despite the higher user count.

#### Throughput Bottleneck [Bonus]
As shown in the [Efficiency Curve](pictures/distributed%20loadgen%20test/Efficiency%20Curve.png), the Requests Per Second (RPS) remained almost perfectly flat at ~2.15 RPS, regardless of the user load (50 to 5,000 users). This suggests a hard bottleneck in the system. Given that the failure rate remained near zero, this isn't a "crash" but likely a software-level rate limit or a synchronous processing bottleneck in the frontend service that prevents higher throughput on the current hardware.

| Efficiency Curve | Performance Knee |
| :---: | :---: |
| ![Efficiency Curve](pictures/distributed%20loadgen%20test/Efficiency%20Curve.png) | ![Performance Knee](pictures/distributed%20loadgen%20test/Performance%20Knee.png) |
| *RPS vs User Load* | *P95 Latency vs User Load* |

#### Infrastructure Health (Grafana Insights)

By correlating Locust data with my Custom Grafana Dashboard, I observed the following during the "Panic Test":
- CPU usage: Several pods reached their limits, but CPU throttling was managed effectively by the Kubernetes scheduler, preventing service death.
- Memory: Remained stable across all tiers, confirming that the e2-medium nodes (4GB RAM) were sufficient for this specific architectural bottleneck.
- Resilience: The near-zero failure rate across all tiers proves that the "Online Boutique" is highly resilient, though its throughput capacity is currently capped.
</details>

<details>
<summary><b>View Infrastructure Health (Grafana Dashboard per Test)</b></summary>

<br>

Select a specific test phase to view the corresponding Grafana metrics:

* <details>
  <summary>Phase 1: Base Load (50 Users)</summary>
  
  ![Base Load](pictures/distributed%20loadgen%20test/1-%20Base%20Load.png)
  </details>

* <details>
  <summary>Phase 2: Load Test (200 Users)</summary>
  
  ![Load Test](pictures/distributed%20loadgen%20test/2-%20Load%20Test.png)
  </details>

* <details>
  <summary>Phase 3: Stress Test (500 Users)</summary>
  
  ![Stress Test](pictures/distributed%20loadgen%20test/3-%20Stress%20Test.png)
  </details>

* <details>
  <summary>Phase 4: Break Test (1000 Users)</summary>
  
  ![Break Test](pictures/distributed%20loadgen%20test/4-%20Break%20Test.png)
  </details>

* <details>
  <summary>Phase 5: Panic Test (5000 Users)</summary>
  
  ![Panic Test](pictures/distributed%20loadgen%20test/5-%20Panic%20Test.png)
  </details>

* <details>
  <summary>Phase 6: Overall Summary View</summary>
  
  ![Overall View](pictures/distributed%20loadgen%20test/6-%20Overall%20view.png)
  </details>

<br>

> **Note:** The metrics displayed include **CPU usage**, **Throttling**, **Memory usage**, and **Request Rate** per pod.

</details>

#### Final Reflection

The experiment shows that while the cluster is extremely stable (no failures at 5,000 users), simply adding more users does not result in more processed requests. To improve performance. 

## 6. Canary Releases & Rollback Strategy

### Methodology: Kubernetes Native Traffic Splitting
I chose the productcatalogservice for this exercise. To implement a canary release without an external Service Mesh (like Istio), I utilized the native behavior of Kubernetes Services, which distributes traffic across all pods matching the service selector.

#### Phase 1: The 25% Canary Deployment
To achieve a 25% traffic split to the new version (v2), I deployed productcatalogservice-v2 alongside the stable version. I managed the traffic ratio by controlling the number of replicas:
- Version 1 (Stable): 3 Replicas
- Version 2 (Canary): 1 Replica
- Total: 4 Pods (1/4 = 25% traffic to v2).
**Validation:** To verify the split, I monitored the Request Rate per pod in my custom Grafana dashboard.

#### Phase 2: Zero-Downtime Transition to v2

To fully switch to v2, I followed a "Scale-before-Shrink" approach:
- Scale Up v2: Increased productcatalogservice-v2 to 3 replicas.
- Readiness Check: Waited for Kubernetes readiness probes to confirm v2 was healthy.
- Scale Down v1: Set productcatalogservice (v1) replicas to 0.
This ensured that the Service always had active endpoints, preventing any disruption to in-flight requests during the transition.

#### Phase 3: Defective Version (v3) & Manual Rollback [Bonus]
For the advanced task, I deployed a version v3 which introduced an artificial delay.
Observation & Detection: Instead of a simple "up/down" check, I used the Monitoring Stack to detect the defect. By observing CPU Usage vs. Request Latency in Grafana, I noticed that v3 pods were "idling" (low CPU usage) despite having high response times. This indicated that the pods were blocked by the artificial delay rather than performing actual computation.

**Rollback Procedure:** Once the defect was confirmed, I performed a manual rollback to restore system stability:
```Bash

kubectl delete deployment productcatalogservice-v3
kubectl scale deployment productcatalogservice-v2 --replicas=3
```

By deleting the v3 deployment, the Kubernetes Service immediately stopped routing traffic to the latent pods, returning the application to the stable v2 state.

## Final Project Reflection

Throughout this assignment, I have progressed from manual cloud configuration to a fully automated, observed, and resilient infrastructure. By combining Terraform, Ansible, and Kubernetes, I created a system that is not only easy to deploy but also transparent enough to debug during complex operations like Canary releases.