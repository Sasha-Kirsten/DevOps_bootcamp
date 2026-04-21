To set up and deploy a Spring Boot application on a DigitalOcean Droplet, you have followed a series of steps to prepare the server environment and install necessary software management tools. 
Summary of Deployment Steps
Server Access and Preparation
Access via SSH: You connected to your DigitalOcean Droplet as the root user.
System Update: You ran sudo apt update to refresh the package index, ensuring the server has the latest metadata for new installations.
Java Environment Setup
Install Java Runtime (JDK): Since Spring Boot requires a Java environment, you installed the OpenJDK (such as openjdk-17-jdk) using the standard apt package manager.
Verification: You verified the installation with java -version to ensure the runtime was active.
SDKMAN! Installation (Alternative Manager)
Install Dependencies: You prepared for SDKMAN! by installing zip and unzip.
Correcting Installation Command: You resolved a syntax error by switching from the main website URL to the dedicated installation script at https://sdkman.io.
Shell Activation: You initialised the tool in your current session using source "$HOME/.sdkman/bin/sdkman-init.sh".
Spring Boot Deployment Options
Direct CLI Installation: You used SDKMAN! to install the Spring Boot CLI with sdk install springboot, providing a quick way to manage versions.
Application Deployment: You explored methods to run your app, such as transferring a .jar file from your local machine via SCP and executing it with java -jar. 
DigitalOcean
DigitalOcean
 +8
Summary of Commands Used
Action 	Command
Update Packages	sudo apt update
Install Java	sudo apt install openjdk-17-jdk
Install SDKMAN!	curl -s "https://sdkman.io" | bash
Install Spring Boot CLI	sdk install springboot
Run Application	java -jar your-app.jar
Would you like to continue by setting up a database or a reverse proxy like Nginx for your application?
