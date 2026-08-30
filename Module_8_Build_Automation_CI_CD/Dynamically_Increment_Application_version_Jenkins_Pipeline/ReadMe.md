
# Dynamically Increment Application Version in Jenkins Pipeline

## Overview
This module demonstrates how to automatically increment application version numbers within a Jenkins CI/CD pipeline, build a Java application using Maven, containerize the application, and push it to Docker Hub.

## Objectives
- Understand version management strategies
- Implement dynamic sematic versioning increments using Groovy
- Integrate versioning into Jenkins Pipeline
- Track version changes in source control by commiting tag updates back to Git
- Push the builded Image of the Maven application to the Docker Repo. 
- Use groovy script to store reusable pipeline logic (`CI_step.groovy`)


## Key Concepts
- **Semantic Versioning**: Major.Minor.Patch format
- **Automated Incrementing**: Scripted patch version updates using string tokenization in Groovy 
- **Pipeline Integration**: Using a declaritive `Jenkinsfile` combined with external Groovy scripts for execution logic
- **Credential Management**: Securely passing Docker Hub credentials to the pipeline

## Steps to complete the projects
- **First Step**: Create a Dockerfile for the application so that the app would be containerised and have the required verions of tools.
- **Second Step**: Create the necessary pom.xml file for the java application to run properlly. 
- **Third Step**: After testing that all is working, for the container and the creation of maven application, we need to create a pipeline for the Continous Integration pipeline.
- **Fourth Step**: After creating the initial pipeline, stages in Jenkins (the automation tools for the pipeline) need to be created in a methodological order.  
- **Fifth Step**: 
- **Sixth Step**:

## Prerequisites
- Jenkins instance configured running on docker container
- Git repository and Docker Repository access through storing the credentials on Jenkins 
- Basic understanding of Jenkins Pipelines
- Groovy scripting knowledge

## Contents
- `Jenkinsfile`: The declaritive pipeline configuration.
- `CI_step.groovy`: The extracted Groovy script containing functions for versioning, Maven commands, Docker builds, and Git commits
- `pom.xml`: The Maven configuration file for the Java applications
- `Dockerfile`: The instructions to build the Amazon Corretto Alpine-based Docker Image.

## Getting Started
1. Review the pipeline Jenkinsfile
2. Configure version file in your repository
3. Set up Jenkins credentials for Git operations
4. Run the pipeline and verify version increments

## Next Steps
- Implement file-based version tracking (e.g., storing the version in a `version.txt` or updating it directly inside the `pom.xml` before committing) to persist versions between different Jenkins builds.
- Configure Git to automatically push the new commit to the remote repository.
