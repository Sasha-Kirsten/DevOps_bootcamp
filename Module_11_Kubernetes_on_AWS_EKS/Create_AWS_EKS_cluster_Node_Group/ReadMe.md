# Create AWS EKS cluster with a Node Group 

## Overview


## Prerequisites Technologies: 
# Kubernetes and AWS EKS.

# Steps:

## 1. Create a AWS Roles that are necessary to access, create and execute the commands to use the AWS EKS.
## We are need to go to login onto the AWS and go to the IAM console. Afterwards, we need to go to the Role page and create a Role that we are going to assign..

## 2. Create the Virtual Private Cloud (VPC) with Cloudformation Template for the AWS EKS Worker Nodes. 
### We are going to create the Virtual Private Cloud using Cloudformation with Terraform for the EKS Worker Nodes. 
### This can be done using Terraform because we can see what we are creating and clearly see the state of the AWS resource we are using. Due to the cost of AWS EKS, this approach would minimise the cost of using AWS directly.


## 3. Create EKS cluster (Control Plane Nodes)
### Using Terraform, we create an EKS cluster and assign the attributes of the resource to our requirements



## 4. Create a Node Group for Worker Nodes and attach to EKS cluster.

## 5. Configure Auto-Scaling of worker nodes.

## 6. Deploy a sample application to EKS cluster. 


## Verification

## Resources