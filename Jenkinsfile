pipeline {
    agent any

    environment {
        REGISTRY_URL        = 'harbor.registry.local'
        HARBOR_PROJECT      = 'skr'
        BACKEND_IMAGE_NAME  = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG           = "v${BUILD_NUMBER}"
        VM_USER             = 'ubuntu'
        VM_IP               = '192.168.56.23'
        GIT_REPO            = 'https://github.com/ranjansanjit/DEVOPSFINALPROJECT.git'
        SONAR_PROJECT_KEY   = 'contact-manager'
    }

    stages {
        stage('Checkout') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh """
                    rm -rf DEVOPSFINALPROJECT
                    git clone https://${GITHUB_TOKEN}@github.com/ranjansanjit/DEVOPSFINALPROJECT.git
                    """
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                        /opt/sonar-scanner/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.sources=DEVOPSFINALPROJECT \
                            -Dsonar.host.url=http://192.168.56.22:9000 \
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
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
                        dir('DEVOPSFINALPROJECT/app/backend') {
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
                        dir('DEVOPSFINALPROJECT/app/frontend') {
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
                sshagent(['vm-ssh-key']) {
                    withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} << EOF
                            echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin
                            
                            docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                            docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
                            
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
        success {
            echo "Build SUCCESS for DEVOPSFINALPROJECT #${BUILD_NUMBER}"
        }
        failure {
            echo "Build FAILED for DEVOPSFINALPROJECT #${BUILD_NUMBER}"
        }
    }
}
