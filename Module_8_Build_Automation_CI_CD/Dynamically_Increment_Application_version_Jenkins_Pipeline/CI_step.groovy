def Increment_Version(String currentVersion){
    versionParts = currentVersion.tokenize('.')
    patchVersion = versionParts[2].toInteger() 
    minorVersion = versionParts[1].toInteger()
    majorVersion = versionParts[0].toInteger()
    if(patch_version == 9 and minorVersion == 9){
        patchVersion += 1
    } elif(patchVersion == 9 and minorVersion > 9){
        patchVersion = 0
        minorVersion = minorVersion + 1
        versionParts[1] = minorVersion.toString()

    }
    else {
        patchVersion = 0
        minorVersion = versionParts[1].toInteger() + 1
        versionParts[1] = minorVersion.toString()
    }

    return "${majorVersion}.${minorVersion}.${patchVersion}"
}

// def Build_Java_Application(String mavenApplication){

// }

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
    sh "git commit -m '${gitCommitMessage}'"
    sh "git push origin ${gitBranch}"   
}

