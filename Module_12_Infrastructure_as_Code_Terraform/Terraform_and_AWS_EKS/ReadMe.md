# Creating a Kubernetes cluster in automation approach with Terraform

## Overview
### Automating the provisioning of the Kuberenetes cluster using the Terraform on AWS.

## Prerequisites: 
### -- Access to the AWS and EKS
### -- Terraform 
### -- Docker

# Steps:

## 1. Connect to the AWS by having the right credentials and make sure that the correct account/user is used for the setting up of the service. 

## 2. Make sure that the Terraform is connected to the AWS account using the correct account. 

## 3. Create the Kubernetes Cluster through Elastic Kubernetes Service (EKS). We can create a seperate file for the Kubernetes Cluster as a module in a .tf file.

## 4. While creating a .tf file for EKS, we would need to create a main.tf, variable.tf and the provider.tf. In the main.tf we would store the resource for the Virtual Private Cloud (VPC) that would be environment to deploy the EKS into. 


## Getting Started
1. ### 
2. ### 
3. ### 

## Resources
- [EKS Link on Terraform.io](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- []()
- []()