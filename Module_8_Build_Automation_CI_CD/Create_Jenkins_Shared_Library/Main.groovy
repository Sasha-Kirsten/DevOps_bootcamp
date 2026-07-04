def buildJar(){
    echo "Building the Jar file"
    sh "mvn clean package"
}

def buildImage(String imageName){
    echo "Building the Docker Image"
    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
        sh "echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin"
        sh "docker build -t ${imageName}:latest ."
        sh "docker push ${imageName}:latest"
    }
    // sh "docker build -t my-app:latest ."
}

def deployApp(String deploymentFile){
    echo "Deploying the Application"
    sh "kubectl apply -f ${deploymentFile}"
}

def runMavenTests(){
    echo "Running Unit Tests"
    sh "mvn test"
}

def runMavenIntegrationTests(){
    echo "Running Integration Tests"
    sh "mvn verify -Pintegration-tests"
}

def runMavenE2ETests(){
    echo "Running End-to-End Tests"
    // sh "mvn verify -Pe2e-tests"
    sh "mvn verify -Psecurity-scan"
}

def sercurityScan(){
    echo "Running Security Scan"
    sh "mvn verify -Psecurity-scan"
}

def codeQualityScan(){
    echo "Running Code Quality Scan"
    sh "mvn -B verify sonar:sonar -Dsonar.projectKey=my-app"
}

def dependencyScan(){
    echo "Running Dependency Security Scan"
    sh "mvn org.owasp:dependency-check-maven:check"
}

def containerScan(String imageName){
    echo "Running Container Security Scan"
    // sh "trivy image ${imageName}:latest"
    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageName}:latest"
}