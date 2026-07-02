
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

## 4. Implement the Building Steps
In the Jenkins Freestlye job, we need to go to the Build Steps and implement the secure shell command to build the docker image and push the image to the docker repository and to ...

## 5. Implement the Building Post-build Actions
In the section of Configure  and under the Build Steps, we can implement the after action of the Build Step. 


### 2. Pipeline (Jenkinsfile)
Code-as-infrastructure approach using Groovy DSL.
- Declarative or Scripted syntax
- Version-controlled pipeline definitions
- Better for complex workflows

## 1. Accessing the Jenkins server
After accessing the jenkins server, successfully as in the first step in Freestyle job.
Also, we need to make sure to set up the docker credentials as well, username and password. 

## 2. Set up the environment for Jenkins Script
We need to set the up the envirionment appropriate for the CI task. In this case, we need to set up environment for Maven.

## 3. Create Jenkinsfile
For the creation of the automated CI/CD pipeline, we are going to use a scripted Jenskinsfile. This is for the simplicity and consistency for the task. 
The Jenkinsfile contains the credential variables for the Docker, the building of the jar repository, there is the testing on the Maven code and the deployment for the image onto the docker repository. 

### 3. Multibranch Pipeline
Automatically creates pipelines for different branches.
- Scans repository for Jenkinsfiles
- Isolated builds per branch
- Ideal for development workflows

## 1. Set the Jenkins server
To bulid a full maintainable multi-branch, we need to create the Jenkins project and the Item for the Multibranch Pipeline. 

We need to go to Branch Sources and create a adjust the access the Git repository and use the credentials that we use to store the git repository. The Jenkinsfile should accessable for the Build Configuration. 


## 2. Set up a project for the Multi-branch environment
We need to set up the Multi-branch environment so that we can set up all the needed branches for our Continous Integration/ Continous Deployment pipeline. 
This is ideal for developers working on different branches that specificied for specific use in the pipeline. This would run tests on each branch, the execution deployment only on the main branch, when merged into main: the test, build and deploy app. 

## 3. Create a JenkinsFile for Multi-branch Project
We create a new Jenkinsfile to perform. certain tasks like run docker commands of creating image and then pushing to docker repository, git commands like "git add .", "git commit -m ''" and "git merge ". 

## 4. Add the BRANCH_NAME to th Jenkinsfile
To create a proper working Multi-branch project, we need to add the jenkins syntax for multi-branch:

```Jenkinsfile
when{
    expression{
        BRANCH_NAME == ""
    }
}
```
So would check which branch the jenkinsfile is being executed on and perform these certain tasks. 


<!-- The other sections is optional.  -->


## Getting Started

1. Install Jenkins and required plugins
2. Configure Git/GitHub integration
3. Create your first Jenkinsfile
4. Set up webhook triggers
5. Monitor pipeline execution

## Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkinsfile Syntax Reference](https://www.jenkins.io/doc/book/pipeline/)
