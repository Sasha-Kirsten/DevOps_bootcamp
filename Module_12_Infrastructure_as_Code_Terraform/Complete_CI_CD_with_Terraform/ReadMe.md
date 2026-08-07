## Overview
# Complete CI/CD with Terraform

## Prerequisites: 
# Terraform, Docker, AWS, Git and the Jenskinsfile.


# Steps:
## 1. Create SSH Key Pair
### We will need to create an asyncrous public-private key to access the Elastic Cloud Compute for the provisioning of the server. Instead of using the current server.

## 2. Install Terraform inside Jenkins container
### For the provisioning the server on EC2, we need to install the Terraform onto the Jenkins Container. This would be appropriate to do... 

## 3. Add Terraform configuration to application's git repository 
### This is to save the main.tf Terraform state configuration file onto the git repository so that the cloud infrastructure would have the lasted state of the cloud resources. 

## 4. Adjust Jenkinsfile to add 'provision' step to the CI/CD pipline that provisions EC2 instance.
### Implementing the entire full CI/CD pipeline, we need to include the provision stage on the Jenkins CI/CD pipeline. To make sure that the new server is set up properlly. 

## 5. In the Continous Integration / Continous Deploy project would need to have :
### -- 5.1. Continous Integration step 1: Build artifect for Java Maven application.
#### The Jenkins pipeline, the first stage is to make sure the application is build and optionally stored onto the Artifact Repository.
### -- 5.2. Continous Integration step 2: Build and push Docker Image to Docker Hub.
#### The next stage onto the Jenkins, we create the docker image of the created artifact application. 
### -- 5.3 Continous Deploy step 1: Automatically provision EC2 instance using TF.
#### The third stage of the Jenkins pipeline, onto the Continous Deploy, we need to set up the new server using Terraform.
### -- 5.4 Continous Deploy step 2: Deploy new application version on the provisioned EC2 instance with Docker Compose. 
#### The last but not least important stage of the Jenkins pipeline, we need to deploy images from the Docker Repository Hub. Then start up the Docker Containers with the docker-compose.yaml file.



## Getting Started
1. 
2. 
3.

## Resources
- [AWS S3 Bucket Terraform Page](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [AWS Elastics Kubernetes service Page](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [AWS Lambda Terraform Page](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest)