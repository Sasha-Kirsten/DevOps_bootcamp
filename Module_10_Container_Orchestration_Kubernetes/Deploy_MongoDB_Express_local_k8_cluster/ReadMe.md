### Overview
Deploy MongoDB and Mongo Express into local K8s cluster.

### Prerequisites
Technologies used: Kuberentes, Docker, MongoDB and Mongo Express.

### Contents
Project Description:
1. Setup local K8s cluster with Minikube.
2. Deploy MongoDB and MongoExpress with configuration and crendentials extracted into ConfigMap and Secret.


### Getting Started

## 1. Setting up
For the orchestrated deployment for the MongoDB and Mongo Express. We need to use the kubectl and the minikube, we need to install via homebrew or PowerShell.

```bash
homebrew install kubectl 
homebrew install minikube
```

## 2. Create the Deployment and Configuration files
We went create the deployment.yaml file to list the image to deploy in this case it would be the MongoDB and the Mongo Express.

The deployment.yaml file can be checked in the dirctory of this file. 


## 3. Deploy the MongoDB and Mongo Express


```bash 
kubectl apply -f deployment.yaml
kubectl apply -f configuration.yaml 
```




### Resources


