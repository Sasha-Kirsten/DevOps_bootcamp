def Increment_Version(String currentVersion){
    def versionParts = currentVersion.tokenize('.')
    def majorVersion = versionParts[0].toInteger()
    def minorVersion = versionParts[1].toInteger()
    def patchVersion = versionParts[2].toInteger() 
    
    // Fixed Groovy syntax: '&&' instead of 'and', 'else if' instead of 'elif'
    if(patchVersion == 9 && minorVersion == 9){
        patchVersion += 1
    } else if(patchVersion == 9 && minorVersion > 9){
        patchVersion = 0
        minorVersion = minorVersion + 1
        versionParts[1] = minorVersion.toString()
    } else {
        patchVersion += 1
    }

    return "${majorVersion}.${minorVersion}.${patchVersion}"
}

def Maven_clean_and_build(String mavenApplication){
    sh "mvn clean package -f ${mavenApplication}/pom.xml"
    sh "mvn clean install -f ${mavenApplication}/pom.xml"
}

def Build_Docker_Image(String dockerImageName, String dockerTag){
    sh "docker build -t ${dockerImageName}:${dockerTag} ."
}

def Push_Docker_Image(String dockerImageName, String dockerTag, String dockerUsername, String dockerPassword){
    sh "echo ${dockerPassword} | docker login -u ${dockerUsername} --password-stdin"
    sh "docker push ${dockerImageName}:${dockerTag}"
}

def Commit_Version_Update(String gitUsername, String gitEmail, String gitBranch, String gitCommitMessage){
    sh "git config user.name ${gitUsername}"
    sh "git config user.email ${gitEmail}"
    sh "git add ."
    // sh "git commit -m '${gitCommitMessage}'"
    // sh "git push origin ${gitBranch}"
    sh "git commit -m 'Increment version ${patch_version}' || true"

}

return this 