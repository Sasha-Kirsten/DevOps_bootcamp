# Ansible Integration in Terraform

## Overview

### Create Ansible Playbook for Terraform integration. 
### Adjust Terraform configuration to execute Ansible Playbook automatically.
### As a result, Terraform could provision a server, it executes an Ansible playbook that configures the server. 

## Prerequisites: 

### 1. We write an Ansible Playbook for the already created Terraform resource block like "null_resource". The Ansible Playbook would consist of all the tasks that we want to execute on a EC2 Instance.
### 2. We integrate the Ansible Playbook into the Terraform's 'null_resource' block that we can use to configure specific servers like EC2 Instance.


# Steps:


## Verification

## Resources