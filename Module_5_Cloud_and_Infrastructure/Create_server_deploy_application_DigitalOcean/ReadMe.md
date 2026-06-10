TASK: Create server and deploy the application (Java and Gradle) onto DigitalOcean.

The technology used to complete the task: DigitalOcean, Linux, Java and Gradle.

The project description: 
1. Setup and configure a server on DigitalOcean.
2. Create and configure a new Linux user on the Droplet (Security best practice).
3. Deploy and run a Java Gradle application on Droplet. 


Records of the process:
I created a cheapest droplet in Frankfurt am Main (Germany).

On my personal computer, I would generate a public and private key and upload the private key the droplet server and then connect to the server using the root@ip_address to secure a connection for uploading application to the droplet server. 

Before accessing the droplet server, I created a firewall that only take my IP addrress for the inbound rule. Everytime, before I login, I would update my IP address for the inbound rule for the firewall.

On the web console, I executed the command: sudo apt upgrade. I chose to execute this command first is to make sure that the droplet server had the latest updated applications and that there are no outdated application.

After the update is completed, I would install the java onto the droplet server. This is so that the java application would be able to execute. 

Then I used the secure copy protocol (scp) to transfer files from my local computer onto the droplet server. But before transfer the Java-Gradle application, I would compress the application, to reduce the load to transfer the file to the droplet server. 




