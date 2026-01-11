pipeline {
    agent any

    environment {
        REGISTRY_URL        = 'harbor.registry.local'
        HARBOR_PROJECT      = 'skr'
        BACKEND_IMAGE_NAME  = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG           = "v${BUILD_NUMBER}"
        // Add your VM details here
        VM_USER             = 'ubuntu' // or your specific user
        VM_IP               = '192.168.56.23' // Change to your VM's IP
    }

    stage('SonarQube Analysis') {
    steps {
        // withSonarQubeEnv automatically handles the URL and Token 
        // using the credentials you linked to "SonarQube-Server" in Jenkins settings
        withSonarQubeEnv('SonarQube-Server') {
            sh """
            /opt/sonar-scanner/bin/sonar-scanner \
            -Dsonar.projectKey=contact-manager
            """
        }
    }
}

stage("Quality Gate") {
    steps {
        // Added a 20-second sleep to ensure the background task starts 
        // before Jenkins starts checking for the result.
        sleep 20
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}

        stage('Build & Tag Images') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('app/backend') {
                            sh """
                                docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest .
                                docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest \
                                           ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('app/frontend') {
                            sh """
                                docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest .
                                docker tag ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest \
                                           ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
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
                        echo "\$HARBOR_PASS" | docker login ${REGISTRY_URL} -u "\$HARBOR_USER" --password-stdin
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
                // Requires 'ssh-agent' plugin and 'vm-ssh-key' credentials in Jenkins
                sshagent(['vm-ssh-key']) {
                    withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} << 'EOF'
                                # Login to Harbor on the VM
                                echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin
                                
                                # Pull latest images
                                docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                                docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
                                
                                # Restart containers (Assuming docker-compose.yml is already on the VM)
                                # If you don't have compose, we can run them manually:
                                docker stop backend frontend || true
                                docker rm backend frontend || true
                                
                                docker run -d --name backend -p 8080:8080 ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                                docker run -d --name frontend -p 80:80 ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
EOF
                        """
                    }
                }
            }
        }
    }

    post {
        success { echo "Build SUCCESS for DEVOPSFINALPROJECT #${BUILD_NUMBER}" }
        failure { echo "Build FAILED for DEVOPSFINALPROJECT #${BUILD_NUMBER}" }
    }
}