# Ansible Integration Jenkins

## Overview

### We need to configure a dedicated server for Jenkins. Create and configure a dedicated server for Ansible Control Node. 

### Use the Ansible Playbook to configure the EC2 Instances. 

### Apply the best security practices, using ssh key file in Jenkins for the Ansible Control Node and Ansible Managed Node servers. 

<!-- ### We are using Jenkins to execute stages into two steps. First create copy files for the ansible server, and then configure the ec2 instance.  -->



## Prerequisites: 


# Steps:
## 1. We need to build the Jenkins pipeline, to build an automated pipeline steps for Ansible to execute configuration of e2 instance. 

## 2. After completing the Jenkins pipeline, we need to build configuration file for Ansible in the inventory_aws_ec2.yaml. 

## 3. We need to create an ansible.cfg to store the files values like inventroy, remote_user and private_key_file.

<!-- ## 4.1 Connect to the remote Ansible Control Node server -->
<!-- ## 4.2 Copy Ansible playbook and configuration files to the remote Ansible Control Node server-->
<!-- ## 4.3 Copy the ssh keys for the Ansible Managed Node servers to the Ansible Control Node server-->
<!-- ## 4.4 Install Ansible, Python3 and Boto3 on the Ansible Control Node server -->
<!-- ## 4.5 With everything installed and copied to the remote Ansible Control Node server, execute the
playbook remotely on that Control Node that will configure the 2 EC2 Managed Nodes -->



## Resources
## -- Ansible 