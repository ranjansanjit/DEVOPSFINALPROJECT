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
    }

    stages {
        stage('Clean & Checkout') {
            steps {
                deleteDir()
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh "git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/ranjansanjit/DEVOPSFINALPROJECT.git ."
                }
                // This lists every file in the console so you can see the REAL paths
                sh "find . -maxdepth 3 -not -path '*/.*'"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                            sh """
                            /opt/sonar-scanner/bin/sonar-scanner \
                              -Dsonar.projectKey=contact_manager \
                              -Dsonar.projectName="Contact Manager" \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://192.168.56.22:9000 \
                              -Dsonar.login=${SONAR_TOKEN} \
                              -Dsonar.scm.disabled=true \
                              -Dsonar.ws.timeout=300
                            """
                        }
                    } catch (Exception e) {
                        echo "SonarQube failed, but proceeding: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Build & Tag Docker Images') {
            parallel {
                stage('Backend') {
                    steps {
                        script {
                            // Automatically find the folder containing the backend Dockerfile
                            def backendDir = sh(script: "dirname \$(find . -name Dockerfile | grep -i backend | head -n 1)", returnStdout: true).trim()
                            dir(backendDir) {
                                sh "docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest ."
                                sh "docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}"
                            }
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        script {
                            // Automatically find the folder containing the frontend Dockerfile
                            def frontendDir = sh(script: "dirname \$(find . -name Dockerfile | grep -i frontend | head -n 1)", returnStdout: true).trim()
                            dir(frontendDir) {
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
    ports:
      - "8080:8080"
    restart: always
  frontend:
    image: ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
    container_name: frontend
    ports:
      - "80:80"
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
        success { echo "Build SUCCESS #${BUILD_NUMBER}" }
        failure { echo "Build FAILED #${BUILD_NUMBER}" }
    }
}