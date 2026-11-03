# Configure shared Remote State

## Overview


## Prerequisites: 


# Steps:


## Verification

## Resources


Demo Project:
Create EKS cluster with eksctl
Technologiesused:
Kubernetes, AWS EKS, Eksctl, Linux
Project Description:
Create EKS cluster using eksctl tool that reduces the
manual effort of creating an EKS cluster


brew install weaveworks/tap/eksctl 

aws configure list 

eksctl create cluster \
> --name demo-cluster \
> --version 1.27 \
> --region eu-central-1 \
> --nodegroup-name demo-nodes \
> --node-type t2.micro \
> --nodes 2 \
> --nodes-min 1 \
> --nodes-max 3



1) create EKS IAM Role
2) create VPC for Worker Nodes 
3) create EKS cluster (Control Plane Nodes)
4) connect kubectl with EKS cluster
5) create EC2 IAM Role for Node Group 
6) create Node Group and attach to EKS cluster 
7) configure auto-scaling 
8) deploy our application to our EKS cluster







# Create an Amazon EKS Cluster with eksctl

## Demo Project

**Project:** Create an Amazon EKS Cluster with eksctl  
**Technologies:** AWS, Amazon EKS, Kubernetes, eksctl, AWS CLI, kubectl, Linux/macOS  
**Goal:** Provision a managed Kubernetes cluster on AWS with `eksctl`, verify access with `kubectl`, and safely remove the infrastructure when finished.

## Overview

This project demonstrates how to create and manage an Amazon Elastic Kubernetes Service (EKS) cluster using `eksctl`.

`eksctl` automates much of the AWS infrastructure required for EKS, including the control plane, networking, IAM roles, managed worker nodes, and autoscaling configuration. Using a version-controlled cluster configuration file makes the deployment easier to review and reproduce than a long one-line command.

> This project is intended for a learning or sandbox environment. Amazon EKS, EC2 worker nodes, EBS volumes, load balancers, and networking resources can create AWS charges. Delete the cluster after testing.

## Architecture

```text
Developer workstation
  │
  │ eksctl create cluster -f cluster.yaml
  ▼
AWS Account
  │
  ├─ Amazon EKS control plane
  │
  ├─ VPC, subnets, route tables, and security groups
  │
  ├─ Managed node group
  │    └─ EC2 worker nodes
  │
  └─ IAM roles and OIDC provider
       │
       ▼
Kubernetes workloads



## Write these parts yourself first

To make it feel genuinely yours, write these sections in your own voice:

- **Overview** — explain why you chose `eksctl`.
- **Architecture** — explain what AWS resources you expect `eksctl` to create.
- **Configuration** — explain your choices for region, nodes, and autoscaling.
- **Portfolio demonstration** — explain what you would show someone live.
- **Security and production considerations** — explain what you would improve beyond a learning cluster.

## Avoid writing these claims until true

Do not write:

- “The cluster was successfully deployed” unless you really created it.
- “The application is live” unless you tested it.
- “Production ready” for a basic public EKS cluster.
- “No cost” — EKS and associated AWS resources cost money.

Instead write:

> “The configuration is prepared for a sandbox deployment and has been reviewed locally. Live provisioning requires an AWS account, approved budget, and explicit execution of the cluster creation command.”

That honesty makes the project more credible.