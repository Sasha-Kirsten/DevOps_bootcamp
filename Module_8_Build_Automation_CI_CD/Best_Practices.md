# Best Practices

## Pipeline Script/Jenkinsfile best practices:
### 1. Use Pipeline as Code: Store your Jenkinsfile in Git Repository  (instead of inline script in Jenkins). Good for history, working in a team etc.
### 2. Call your Pipeline script the default name: Jenkinsfile
### 3. Non-Setup work should occur within a stage block. Makes your builds easier to visualize, debug etc.
### 4. Make sure to put `#!/usr/bin/env` groovy at the top of the file so that IDEs, GitHub diffs, etc properly detect the language and do syntax highlighting for you.
### 5. Input Parameter: input should not be done within a node block. It is recommmended to use a timeout for the input step in order to avoid waiting for an infinite amount of time, and also control strucuture (try/catch/finally)

## Other best practices:
### 1. Use Automtic versioning
### 2. Store common pipeline code in a Shared Library, so that it can be used by other project/teams.
### 3. Access Control: 
#### Security Realm: Simplest Authentication Scheme. We need to enable the Security checkbox, so that the users need to login with their credentials and avoid any tresspassing. Another feature to include, for large organizations with external identity provider using LDAP. Make sure that you install LDAP plugin. This delegates all authentication to a configured-on LDAP server, including both users and groups. 
<!-- #### Authorization: There are different Authorization   -->
### 4. Protecting Jenkins Users froim other Threats:
#### 1. Cross Site Request Forgery (CSRF) Protection: This prevents a remote attack againist Jenkins running inside the firewall. This can enabled in the settings of Jenkins. 
#### 2. For the builds that run on master node, due to the maste node capability 



### 5. Backup the JENKINS_HOME Directory: 


### 6. Setup a Differenty Job/Project for Each Maintenance or Development Branch Created. 
#### Decteting Issues at an early stage in the development lifecylce. Jenkins offers to build parts of your pipeline in parallel, and one of the critical pratice for Jenkins pipeline implementation. 
#### Setting up different jobs/ projects for each branch helps you support parallel development efforts and maximaize the advantage of sleuthing issues, thereby reducing risk and allowing developers to be more productive. 


### 7. Prevent Resource Collisions in Jobs that are running in Parallel:


### 8. Use "File Fingerprinting" To Manage Dependecies
#### This is important because in project keeping track  of which. verison of it is used and by which version of it. The best practices is to record fingerprinitng of jar files. Record all fingerprinting of the following: jar files that your project produces and jar files that your project relies on. 


### 9. Avoid Complicated Groovy Codesode in Pipelines

### 10. Build A scalable Jenkins Pipeline
#### This feature to have in your Jenkins pipeline. For instance, having Shared Libraries are perhaps the single most talked about tool to pop up across enterprise and are the pinncle of applying DRY (Don't Repeat Yourself) to Devops. The shared libraries offer a version-controlled management (SCM) compared to a common programming library. 
#### One of the way to approachs is using Global shared libraries. Or folder-level through managing that specifc folder. The other approach is use `@library` using the library name within the Jenkinsfile will allow a pipeline to access that shared library. 
<!-- #### When you have a basic shared libraries, be ready to look at the Jenkins  -->

### 11. Manage Declaritive Syntax/Declaritive Pipelines
#### In an enterprise-level adoptation of the Jenkins implementation, it is a huge step towards the accessibility of enterprise shared practices for anyone looking to take advantage of Pipelines. 
#### The declaritive pipelines configuration tells a system what to do, shifting the complexity of 'how to do' to the system.
#### Pipelines are perhaps the easiest tool to get started within Jenkins and are accesible by creating a new Pipeline 'Item' in the Blue Ocean or classic Jenkins UI, or by the writing your Jenkinsfile and commiting it to your project's SCM repo. 

### 12. Maintain Higher Test Code Coverage & Run Unit Test As Part of Your Pipeline

### 13. Monitor Your CI/CD Pipeline 
#### This is important because when could get broken pipeline, it stalls the development team from being able to do their work. The best approach to this is to install Jenkins Slack plugin sends error notification to channels monitored by on-call engineers. The plugin will monitor the health of the jobs and enables the user to recognize potential areas of the build that might require improvement. 
