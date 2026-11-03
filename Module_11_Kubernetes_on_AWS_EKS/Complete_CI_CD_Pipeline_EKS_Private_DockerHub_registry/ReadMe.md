# Configure shared Remote State

## Overview


## Prerequisites: 


# Steps:


## Verification

## Resources

Demo Project:
Complete CI/CD Pipeline with EKS and private DockerHub registry
Technologiesused:
Kubernetes, Jenkins, AWS EKS, Docker Hub, Java, Maven, Linux, Docker,Git
Project Description:
Write K8s manifest files for Deployment and Service configuration
Integrate deploy step in the CI/CD pipeline to deploy newly built application image from
DockerHub private registry to the EKS cluster
So the complete CI/CD project we build has the following configuration:
a.CI step:Increment version
b.CI step: Build artifact for Java Maven application
c.CI step: Build and push Docker image to DockerHub
d.CD step: Deploy new application version to EKS cluster
e.CD step: Commit the version update





<root@-----> apt-gel install gettext-base 

<root@-----> envsubst 


kubectl get node

kubectl create secret docker-registry my-registry-key \
--docker-server=docker.io \
--docker-username=aleks \
--docker-password= --- \
