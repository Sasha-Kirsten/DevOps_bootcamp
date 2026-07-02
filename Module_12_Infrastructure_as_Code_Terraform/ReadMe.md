Infrastrucutre as Code (IaC) like Terraform


### The Best practices:
## 1. Manipulate state only through Terraform commands:
# We do not edit the file directly. 

## 2. Always set up a shared remote storage:
# We store the terrafrom.tfstate on cloud service like AWS (S3).

## 3. Use State Locking:
# Lock state file unitl writing of state file is completed.

## 4. Back up your state file:
# On the cloud service, like AWS S3, enable versioning on the bucket. 

## 5. Use 1 State per Environment:
# For each environment: Dev, Test and Prod. We need to follow the IaC trend: GitOps. 

## 6. Host TF scripts in Git repository:
# Effective team collaboration. Version control for your IaC code. 

## 7. Continous Integration for Terraform Code:
# Treat TF code just like your Application Code. Review TF Code and Run Automated Tests.

## 8. Apply Infrastructure Changes ONLY through Continous Deploy pipeline:
# Execute Terraform in an automated build. 
