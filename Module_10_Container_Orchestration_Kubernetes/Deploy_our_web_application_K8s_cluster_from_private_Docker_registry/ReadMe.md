TASK: Deploy our web application in K8s cluster from private Docker registry.

Techologies used: Kubernetes, Helm, AWS Elastic Container Registry and Docker. 

Project Description:
1. Create Secret for credentials for the private Docker registry.
2. Configure the Docker registry secret in application Deployment component.
3. Deploy web application image from our private Docker registry in K8s cluster. 







docker login:
--password-stdin

aws ecr get-login-password --region eu-central | docker login --username AWS --password-stdin xxxx-xxx-eu-central-1.amazonaws.com 


cat .docker/config.json 


aws ecr get-login-password 


minikube ssh

docker login --username AWS -p XXXXXX


minikube cp minikube:/home/docker/.docker/config.json  /users/name/.docker/config.json 


kubectl create secret generic my-registry-key --from-file=.dockerconfigjson=.docker/config.json --type=kubernetes.io/dockerconfigjson 

kubectl get secret (-o yaml)

kubectl create secret docker-registry my-registry-key-two --docker-service=https://XXXX.dkr.ecr.eu-central-1.amazonaws.com --docker-username= --docker-password=