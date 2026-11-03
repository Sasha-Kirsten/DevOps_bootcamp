# Configure shared Remote State

## Overview


## Prerequisites: 


# Steps:


## Verification

## Resources


Demo Project:
Complete CI/CD Pipeline with EKS and AWS ECR
Technologiesused:
Kubernetes, Jenkins, AWS EKS, AWS ECR, Java, Maven, Linux, Docker, Git
Project Description:
Create private AWS ECR Docker repository
Adjust Jenkinsfile to build and push Docker Image to AWS ECR
Integrate deploying to K8s cluster in the CI/CD pipeline from AWS ECR private registry
So the complete CI/CD project we build has the following configuration:
a.CI step:Increment version
b.CI step: Build artifact for Java Maven application
c.CI step: Build and push Docker image to AWS ECR
d.CD step: Deploy new application version to EKS cluster
e.CD step: Commit the version update


kubectl get secret

kubectl create secret docker-registry aws-registry-key --docker-server=xxxxxx --docker-username=AWS \
> --docker-password= xxxxxx



