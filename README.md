# Discovering GCP & GKP
This repo is a lab assignmenet in the context of cloud computing course aiming in applying all the theory learned during the courses in a practical enviroment such as google cloud using the kubernetees tool

## Notes
- Curently using the e2-medium instances, might have to upgrade later as they only have 4GB of RAM
- To access frontend in a browser use the outputed ip of this command:
    kubectl get service frontend-external | awk '{print $4}'
- If we deploy the project using -f kubernetes-manifests this will just apply all the files exactly as written. On the other hand the Kustomize Base follows a "Base and Overlay" pattern.

## Journal
### Configuration:
running the start up script run-conf.sh to host project on GCP (must manually change variable names if needed)
    ./run-conf.sh

### Reconfiguring the application
Using the kustomize tool we are able to reduce the CPU usage.
The first step will be to disable the loadgenerator using this command:
    kustomize edit add component components/without-loadgenerator
This will update the `kustomize/kustomization.yaml`. If we apply this new configuration using
    kubectl apply -k .
The loadgenerator will still be active since we didnt delete the previous running pod, we then just have to manually delete it:
    kubectl delete deployment loadgenerator

### Deploying automatically a VM
After deploying the vm's using terraform using `./script/vm-allocation.sh` run the wanted Ansible script for testing `./script/loadgen.sh`
The first script will launch terraform and create the wanted specifications in the `testing/setup.sh` file and saves all the vm's ip in the `testing/hosts` file. Once that done that ansible will deploy the wanted script on those VM. 