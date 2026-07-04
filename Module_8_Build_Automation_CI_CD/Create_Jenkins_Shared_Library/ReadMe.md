
# Create Jenkins Shared Library

## Overview
This module covers creating and implementing a Jenkins Shared Library for build automation and CI/CD pipelines.

## Contents
- Shared Library structure and organization
- Groovy scripting for Jenkins
- Creating reusable pipeline steps
- Best practices for library maintenance

### Steps of creation and reusage of Groovy Script
## 1.Create a Groovy script
In the groovy script, we need to write the specific functions that we want to create that would be reuable in many Jenkinsfiles.
To use the specific functions we need to call them in the specific stage that we want this functions' code to be executed.

## 2. Create a Jenkinsfile
In the Jenkinsfile, write the stage that should be executed for Continous Integration pipeline. 


## 3. Write the groovy script into the Jenkinsfile
Call the functions from the Groovy script and make sure their are no error when calling the functions.

For using other application like Sonar, we need to install the application on the server that we are running the Jenkins on.

## Prerequisites
- Jenkins instance configured
- Understanding of Declarative and Scripted Pipelines
- Basic Groovy knowledge

## Getting Started
1. Clone this repository
2. Review the shared library structure
3. Follow the examples in each section
4. Integrate into your Jenkins environment

## Resources
- [Jenkins Shared Library Documentation](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Groovy Documentation](https://groovy-lang.org/documentation.html)
