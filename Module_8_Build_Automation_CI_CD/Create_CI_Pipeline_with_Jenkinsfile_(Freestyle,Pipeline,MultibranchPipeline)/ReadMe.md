
# Create CI Pipeline with Jenkinsfile

## Overview
This module covers creating Continuous Integration (CI) pipelines using Jenkins with different pipeline types: Freestyle jobs, Declarative Pipeline, and Multibranch Pipeline.

## Objectives
- Understand Jenkins pipeline fundamentals
- Create Freestyle job configurations
- Write Declarative Jenkinsfile syntax
- Implement Multibranch Pipeline for multiple branches
- Integrate with version control systems

## Pipeline Types

### 1. Freestyle Jobs
Traditional Jenkins job configuration through the UI.
- Manual job setup
- GUI-based configuration
- Best for simple pipelines

## 1. Accessing Jenkins Server
After running the Jenkins container, we need to get the initialAdminPassword (in /var/jenkins_home/secrets/initialAdminPassword) to access the Jenkins Server. 
```bash
docker ps 
docker log jenkins_container
```

## 2. Install application and Plugin
Install the necessary application and the plugins that is needed for the 
Jenkins server to run compatible with any used application, using the GUI at Jenkins Server.

## 3. Create Crendentials for Jenkins
To properlly use Jenkins to work flawlessly with other applications like Docker and AWS.
The username, password, ssh key (private key).

### 2. Pipeline (Jenkinsfile)
Code-as-infrastructure approach using Groovy DSL.
- Declarative or Scripted syntax
- Version-controlled pipeline definitions
- Better for complex workflows

## 1. Accessing the Jenkins server
After accessing the jenkins server, successfully as in the first step in Freestyle job.
Also, we need to make sure to set up the docker credentials as well, username and password. 

## 2. Set up the environment for Jenkins Script
We need to set the up the envirionment appropriate for the CI task. In this case, we need to set up environment for Maven and Node.

## 3. 

### 3. Multibranch Pipeline
Automatically creates pipelines for different branches.
- Scans repository for Jenkinsfiles
- Isolated builds per branch
- Ideal for development workflows

## Getting Started

1. Install Jenkins and required plugins
2. Configure Git/GitHub integration
3. Create your first Jenkinsfile
4. Set up webhook triggers
5. Monitor pipeline execution

## Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkinsfile Syntax Reference](https://www.jenkins.io/doc/book/pipeline/)
