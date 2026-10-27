def mavenVerify(String applicationDirectory = '.') {
    dir(applicationDirectory) {
        sh 'mvn --batch-mode clean verify'
    }
}

def buildImage(String applicationDirectory, String imageRepository, String imageTag) {
    dir(applicationDirectory) {
        withEnv(["IMAGE_REFERENCE=${imageRepository}:${imageTag}"]) {
            sh 'docker build --tag "$IMAGE_REFERENCE" .'
        }
    }
}

def publishImage(String sourceRepository, String imageTag, String targetImage, String credentialsId) {
    def registryHost = targetImage.tokenize('/')[0]

    withEnv([
        "SOURCE_IMAGE=${sourceRepository}:${imageTag}",
        "TARGET_IMAGE=${targetImage}",
        "REGISTRY_HOST=${registryHost}"
    ]) {
        withCredentials([usernamePassword(
            credentialsId: credentialsId,
            usernameVariable: 'REGISTRY_USERNAME',
            passwordVariable: 'REGISTRY_PASSWORD'
        )]) {
            sh '''
                printf '%s' "$REGISTRY_PASSWORD" | docker login "$REGISTRY_HOST" --username "$REGISTRY_USERNAME" --password-stdin
                docker image tag "$SOURCE_IMAGE" "$TARGET_IMAGE"
                docker image push "$TARGET_IMAGE"
                docker logout "$REGISTRY_HOST"
            '''
        }
    }
}

def deployManifest(String manifestPath) {
    withEnv(["MANIFEST_PATH=${manifestPath}"]) {
        sh 'kubectl apply --filename "$MANIFEST_PATH"'
    }
}

def call() {
    error('Call a specific ciSteps method, such as ciSteps.mavenVerify(...).')
}