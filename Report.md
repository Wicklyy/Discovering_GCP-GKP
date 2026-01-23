Participant ROUIBAH Ryan



# Questions:

## In the README file, it is suggested to start a GKE cluster configured in “Autopilot” mode (as opposed to “standard” mode). Using this mode would solve the problem we just observed. Briefly explain what is this Autopilot mode and why it hides the problem.
In Autopilot: Google would automatically add more power if needed.
Right now we are locked into 3 e2-medium nodes which are instances restricted to 4GB of RAM. If the app fails to deploy because of "Insufficient memory," we will need to resize our cluster manually. Using Autopilot Google will be the one handling the scale and give more power as needed.

## Which of the two parameters (requests and limits) actually matters when Kubernetes decides that it can deploy a service on a worker node?
The requests parameter is the one that matters for deployment decisions. If there is not enough ressource requested for the service, it will not be deployed.

## Ressource reduction:
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

We chose to reduce the requested ressource for these two services:
- emailservice: The email should only be sent once after the customer completed his payement and would not notice if it wasn't immediate.
- shippingservice: The shipping cost is a simple calculation done once when the client is about to proceed to the payement, this will not impact the overall experience of the user.


## Technical Analysis: adservice.yaml

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


## Performance evaluation

We will be conducting the following tests:

| Test type | LOCUST_USERS | LOCUST_SPAWN_RATE |
| :--- | :--- | :--- |
Baseline  | 50 | 5 |
Load Test | 200 | 20 |
Stress Test | 500 | 50 |
Break Test | 1000 | 100 |
Panic Test | 5000 | 500 |

We observe something interesting the CPU usage never go over 40% this is probably due of actual customer simulation. But we also notice something important, only one of the nodes actually is impacted from the load, the other nodes are still at peace, we can conclude that the load is not well distributed between the nodes.


| Test Type | Users | RPS (Throughput) | P95 Latency | Failure Rate |
| :---: | :---: | :---: | :---: | :---: |
| Baseline | 50 | 2.15 | 98 ms | 0.19% |
| Load Test | 200 | 2.19 | 52 ms | 0.00% |
| Stress Test | 500 | 2.20 | 39 ms | 0.00% |
| Break Test | 1000 | 2.15 | 46 ms | 0.19% |
| Panic Test | 5000 | 2.14 | 40 ms | 0.00% |

![Efficiency Curve](pictures/distributed%20loadgen%20test/Efficiency%20Curve.png)

We can notice something interesting, the "Warming Up" Effect in our data, the P95 Latency actually improved as the load increased (from 98ms down to ~40ms). This is probably due to the cache warming: The Redis cache and internal metadata caches became populated after the initial baseline test.

The Throughput Bottleneck (Efficiency Curve) We notice in the efficiency_curve.png that our RPS remains almost perfectly flat at ~2.15 requests per second, even when jumping from 50 to 5000 users.

We also notice that the cluster maintained a near-zero failure rate across all tiers, proving high resilience in the current configuration.