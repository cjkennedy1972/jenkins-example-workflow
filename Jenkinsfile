dockerRepoHost = 'docker.io'
dockerRepoUser = 'kingdonb' // (Username must match the value in jenkinsDockerSecret)
dockerRepoProj = 'jenkins-example-workflow'

// these refer to a Jenkins secret "id", which can be in Jenkins global scope:
jenkinsDockerSecret = 'docker-registry-account'

// blank values that are filled in by pipeline steps below:
gitCommit = ''
branchName = ''
unixTime = ''
developmentImage = ''
releaseImage = ''

pipeline {
  agent {
    kubernetes { yamlFile "jenkins/docker-pod.yaml" }
  }
  stages {
    // Build a Docker image and keep it locally for now
    stage('Build') {
      steps {
        container('docker') {
          script {
            gitCommit = env.GIT_COMMIT.substring(0,8)
            branchName = env.BRANCH_NAME
            unixTime = (new Date().time / 1000) as Integer
            developmentImage = "${branchName}-${gitCommit}-${unixTime}"
          }
          sh "docker build -t ${developmentImage} ./"
        }
      }
    }
    // Push the image to development environment, and run tests in parallel
    stage('Dev') {
      parallel {
        stage('Push Development Tag') {
          when {
            not {
              buildingTag()
            }
          }
          steps {
            withCredentials([[$class: 'UsernamePasswordMultiBinding',
              credentialsId: jenkinsDockerSecret,
              usernameVariable: 'DOCKER_REPO_USER',
              passwordVariable: 'DOCKER_REPO_PASSWORD']]) {
              container('docker') {
                sh """\
                  docker login -u \$DOCKER_REPO_USER -p \$DOCKER_REPO_PASSWORD
                  docker push ${developmentImage}
                """.stripIndent()
              }
            }
          }
        }
        // Start a second agent to create a pod with the newly built image
        stage('Test') {
          agent {
            kubernetes {
              yaml """\
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: test
                    image: ${developmentImage}
                    imagePullPolicy: Never
                    securityContext:
                      runAsUser: 1000
                    command:
                    - cat
                    resources:
                      requests:
                        memory: 256Mi
                        cpu: 50m
                      limits:
                        memory: 1Gi
                        cpu: 1200m
                    tty: true
                """.stripIndent()
            }
          }
          options { skipDefaultCheckout(true) }
          steps {
            // Run the tests in the new test container
            container('test') {
              sh (script: "./jenkins/run-tests.sh")
            }
          }
        }
      }
    }
    stage('Push Release Tag') {
      when {
        buildingTag()
      }
      steps {
        container('docker') {
          withCredentials([[$class: 'UsernamePasswordMultiBinding',
            credentialsId: jenkinsDockerSecret,
            usernameVariable: 'DOCKER_REPO_USER',
            passwordVariable: 'DOCKER_REPO_PASSWORD']]) {
            sh """\
              docker login -u \$DOCKER_REPO_USER -p \$DOCKER_REPO_PASSWORD
              docker tag ${developmentImage} ${releaseImage}
              docker push ${releaseImage}
            """.stripIndent()
          }
        }
      }
    }
  }
}
