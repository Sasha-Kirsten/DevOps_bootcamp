sudo yum update -y && sudo yum install -y docker 
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo yum install -y docker-compose
# docker build -t myapp:latest .
docker run -p 8080:80 myapp:latest 

