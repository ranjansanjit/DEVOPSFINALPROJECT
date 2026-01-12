pipeline {
    agent any

    environment {
        REGISTRY_URL = 'harbor.registry.local'
        HARBOR_PROJECT = 'skr'
        BACKEND_IMAGE_NAME = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG = "v${BUILD_NUMBER}"
        VM_USER = 'vagrant' 
        VM_IP = '192.168.56.21'
        MY_EMAIL = 'ranjansanjit@gmail.com'
    }

    stages {
        stage('Clean Workspace') { steps { cleanWs() } }
        
        stage('Checkout') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh "git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/ranjansanjit/DEVOPSFINALPROJECT.git ."
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        withSonarQubeEnv('sonarqube') { 
                            withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                                sh """
                                /opt/sonar-scanner/bin/sonar-scanner \
                                  -Dsonar.projectKey=contact_manager \
                                  -Dsonar.projectName="Contact Manager" \
                                  -Dsonar.sources=. \
                                  -Dsonar.host.url=http://192.168.56.22:9000 \
                                  -Dsonar.login=${SONAR_TOKEN} \
                                  -Dsonar.scm.disabled=true
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Build & Tag Docker Images') {
            parallel {
                stage('Backend') {
                    steps {
                        script {
                            def backendPath = sh(script: "find . -maxdepth 2 -iname 'backend' -type d | head -n 1", returnStdout: true).trim()
                            dir(backendPath ?: '.') {
                                sh "docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest ."
                                sh "docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}"
                            }
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        script {
                            def frontendPath = sh(script: "find . -maxdepth 2 -iname 'frontend' -type d | head -n 1", returnStdout: true).trim()
                            dir(frontendPath ?: '.') {
                                sh "docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest ."
                                sh "docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}"
                            }
                        }
                    }
                }
            }
        }

        stage('Login & Push to Harbor') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                    sh """
                    echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin
                    docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                    docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to VM') {
            steps {
                sshagent(['vm-ssh-sshkey']) {
                    withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} << EOF
                        echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin
                        mkdir -p ~/deploy && cd ~/deploy
                        cat > docker-compose.yml << COMPOSE
version: '3'
services:
  backend:
    image: ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
    container_name: backend
    ports: ["8081:8080"]
    restart: always
  frontend:
    image: ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
    container_name: frontend
    ports: ["80:80"]
    restart: always
COMPOSE
                        docker-compose down || true
                        docker-compose pull
                        docker-compose up -d
EOF
                        """
                    }
                }
            }
        }
    }

    post {
        always { cleanWs() }
        success { 
            mail to: "${MY_EMAIL}",
                 subject: "Pipeline SUCCESS: Build #${BUILD_NUMBER}",
                 body: "Hi Ranjan, your pipeline for ${JOB_NAME} build #${BUILD_NUMBER} was successful!\n\nCheck logs here: ${BUILD_URL}"
        }
        failure { 
            mail to: "${MY_EMAIL}",
                 subject: "Pipeline FAILED: Build #${BUILD_NUMBER}",
                 body: "Hi Ranjan, the build #${BUILD_NUMBER} has failed.\n\nPlease check the console output: ${BUILD_URL}console"
        }
    }
}