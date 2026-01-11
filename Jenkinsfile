pipeline {
    agent any

    environment {
        REGISTRY_URL        = 'harbor.registry.local'
        HARBOR_PROJECT      = 'skr'
        BACKEND_IMAGE_NAME  = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG           = "v${BUILD_NUMBER}"
        VM_USER             = 'ubuntu'
        VM_IP               = '192.168.56.21'
        REPO_URL            = 'https://github.com/ranjansanjit/DEVOPSFINALPROJECT.git'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir() // Clean workspace
            }
        }

        stage('Checkout') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh """
                        git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/ranjansanjit/DEVOPSFINALPROJECT.git
                    """
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                    withSonarQubeEnv('SonarQube-Server') {
                        dir('DEVOPSFINALPROJECT') {
                            sh """
                                /opt/sonar-scanner/bin/sonar-scanner \
                                -Dsonar.projectKey=DEVOPSFINALPROJECT \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://192.168.56.22:9000 \
                                -Dsonar.token=${SONAR_AUTH_TOKEN} \
                                -Dsonar.sourceEncoding=UTF-8
                            """
                        }
                    }
                }
            }
        }

        stage("Quality Gate") {
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
                sshagent(['vm-ssh-sshkey']) {
                    withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} << EOF
                            echo "Connected successfully!"

                            echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin

                            docker stop backend frontend || true
                            docker rm backend frontend || true

                            docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                            docker pull ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest

                            docker run -d --name backend -p 8080:8080 ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                            docker run -d --name frontend -p 80:80 ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
EOF
                        """
                    }
                }
            }
        }

    } // End stages

    post {
        success {
            echo "Build SUCCESS for DEVOPSFINALPROJECT #${BUILD_NUMBER}"
        }
        failure {
            echo "Build FAILED for DEVOPSFINALPROJECT #${BUILD_NUMBER}"
        }
    }
}
