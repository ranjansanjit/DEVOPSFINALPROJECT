pipeline {
    agent any

    environment {
        REGISTRY_URL = 'harbor.registry.local'
        HARBOR_PROJECT = 'devopsfinalproject'
        BACKEND_IMAGE_NAME = 'backend'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG = "v${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: "https://github.com/ranjansanjit/DEVOPSFINALPROJECT"
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('app/backend') {
                    script {
                        sh "sudo docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('app/frontend') {
                    script {
                        sh " sudo docker build -t ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'harbor-creds', usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                    script {
                        sh "echo $HARBOR_PASS | docker login ${REGISTRY_URL} -u $HARBOR_USER --password-stdin"
                        sh "docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker push ${REGISTRY_URL}/${HARBOR_PROJECT}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build SUCCESS for DEVOPSFINALPROJECT #${env.BUILD_NUMBER}"
        }
        failure {
            echo "Build FAILED for DEVOPSFINALPROJECT #${env.BUILD_NUMBER}"
        }
    }
}
