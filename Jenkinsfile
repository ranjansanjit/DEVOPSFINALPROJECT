pipeline {
    agent any

    environment {
        REGISTRY_URL = 'harbor.registry.local'
        HARBOR_PROJECT = 'skr'
        BACKEND_IMAGE_NAME = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG = "v${BUILD_NUMBER}"
        VM_USER = 'ubuntu'
        VM_IP = '192.168.56.21'
        REPO_NAME = 'DEVOPSFINALPROJECT'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh "git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/ranjansanjit/DEVOPSFINALPROJECT.git ."
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // Use the SONAR_TOKEN from Jenkins credentials
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube-Server') {
                        sh """
                        /opt/sonar-scanner/bin/sonar-scanner \
                          -Dsonar.projectKey=contact-manager \
                          -Dsonar.projectName="Contact Manager" \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://192.168.56.22:9000 \
                          -Dsonar.login=sqb_5bfb39c57ea06209c550ed57b868185c23a1f462
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Tag Docker Images') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('app/backend') {
                            sh """
                            docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest .
                            docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}
                            """
                        }
                    }
                }

                stage('Frontend') {
                    steps {
                        dir('app/frontend') {
                            sh """
                            docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest .
                            docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                            """
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

        stage('Deploy to VM using Docker Compose') {
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

                        docker-compose down
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
        success {
            echo "Build SUCCESS for ${REPO_NAME} #${BUILD_NUMBER}"
        }
        failure {
            echo "Build FAILED for ${REPO_NAME} #${BUILD_NUMBER}"
        }
    }
}
