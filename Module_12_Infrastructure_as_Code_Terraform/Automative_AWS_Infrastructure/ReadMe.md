## Overview:
# Automation of the AWS Infrastrucutre, using Terraform (Infrastructure as Code)


## Prerequisites: 
# Terraform


# Steps:

## 1. Create the Terraform files 



## 2. Create the variables of the AWS services that is required for the implementation of infrstructure 

The specific infrastrucutre componenets that we need to create are: Virtual Private Cloud and the internet gateway that we need to access the world wide web.

THe next component that we need to create are subnets for the maintaining the public access to a set of Elastic Cloud Compute instances and the private access to a set of Elastic Cloud Compute instances.

The important component that we need to add are security groups. The reason is that the secuirty group will the firewall for the security group. 

The component that we need to implement is Network Address Translation (NAT) gateway, this would be placed into the public subnet. This is so private subnet can access public subnet to the internet gateway in the virtual private cloud. 

The route table is need to be created for the public subnet and another one for the private subnet. 

Lastly but not least important, we need to create variable for the amazon machine image and the specific instance type for the elastic clound compute that would server the computation load of the application that would be run on it. 

## 3. Connect the Terraform variables

Once we created the Terraform variables, we need to integrate the created variables to consist of other terraform variables that are vital for the variable to function properlly. For instance, a public subnet needs to contain a security group and the network address translation gateway and a route table.

## 4. We need to test the main terraform file to see if the there are any errors. 

## 5. Follow the BEST Practice for implementing the infrastructure using Terraform or another IaC.



## Verification

## Resources





<!-- TASK: -->


<!-- The project description: -->



<!-- Records of process: -->
