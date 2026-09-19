Task: Deploy Micoservices application in Kubernetes with Production & Security Best Practices.


Technologies used: Kuberentes, Redis, Linux and Linode LKE.

Project Description:
1. Create K8s manifests for Deployments and Services for all microservices of an online shop application.
2. Deploy microservices to Linode's managed Kubernetes cluster. 




We are connnecting multiple container with each other.
one would be the frontend container.
one for the cartservice for the Cache using redis. Message broker and the In-memory database.
one load generator, for test load of application.
We are going to connect the different container using ports that would communicate the through the pod. 
all the microservice will be deployed into one namespace. 


after setting up the kube config map, we will need linode kubernetes service. 