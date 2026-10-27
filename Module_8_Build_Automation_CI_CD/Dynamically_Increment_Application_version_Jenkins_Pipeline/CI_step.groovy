def createBuildVersion(String baseVersion, String buildNumber) {
    if (!(baseVersion ==~ /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/)) {
        throw new IllegalArgumentException("BASE_VERSION must use MAJOR.MINOR.PATCH format; received: ${baseVersion}")
    }
    if (!(buildNumber ==~ /^\d+$/)) {
        throw new IllegalArgumentException("BUILD_NUMBER must be numeric; received: ${buildNumber}")
    }

    return "${baseVersion}-ci.${buildNumber}"
}

def mavenVerify(String projectDirectory) {
    sh "mvn --batch-mode clean verify -f '${projectDirectory}/pom.xml'"
}

def buildDockerImage(String imageName, String imageTag) {
    sh "docker build --build-arg APP_VERSION='${imageTag}' --tag '${imageName}:${imageTag}' ."
}

return this