pipeline {
    agent any

    environment {
        REGISTRY_URL         = 'harbor.registry.local'
        HARBOR_PROJECT       = 'skr'
        BACKEND_IMAGE_NAME   = 'backend'
        FRONTEND_IMAGE_NAME  = 'frontend'
        IMAGE_TAG            = "v${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ranjansanjit/DEVOPSFINALPROJECT.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // This must match the 'Name' you gave in Manage Jenkins -> Tools
                    def scannerHome = tool 'SonarScanner' 
                    
                    // This must match the 'Name' you gave in Manage Jenkins -> System
                    withSonarQubeEnv('SonarQube-Server') {
                        sh "${scannerHome}/opt/sonar-scanner/bin/sonar-scanner
                        -Dsonar.projectKey=DEVOPSFINALPROJECT \
                        -Dsonar.projectName=DEVOPSFINALPROJECT \
                        -Dsonar.host.url=http://192.168.56.22:9000 \
                        -Dsonar.login=sqb_5bfb39c57ea06209c550ed57b868185c23a1f462 \
                        -Dsonar.sources=. \
                        -Dsonar.java.binaries=."
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    // Only works if you configured the Webhook in SonarQube UI
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Backend Image') {
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

        stage('Build Frontend Image') {
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

        stage('Login & Push Docker Images') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor-creds',
                        usernameVariable: 'HARBOR_USER',
                        passwordVariable: 'HARBOR_PASS'
                    )
                ]) {
                    sh """
                        echo "\$HARBOR_PASS" | docker login ${REGISTRY_URL} \
                        -u "\$HARBOR_USER" --password-stdin

                        docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:latest
                        docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:latest
                    """
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