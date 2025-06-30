pipeline {
    agent any

    environment {
        PROFILE = 'staging'
        CONTEXT = "${PROFILE}"
        IMAGE_NAME = 'aeonyx/flask-hello'
        TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Source code checked out automatically by SCM'
            }
        }

        stage('Build Docker Image') {
            steps {                
                bat "docker build -t ${IMAGE_NAME}:${TAG} ."
                bat "docker images"
            }
        }

        stage('Load Image to Minikube') {
            steps {                
                bat "minikube -p ${PROFILE} image load ${IMAGE_NAME}:${TAG}"
                bat "minikube -p ${PROFILE} ssh docker images"
            }
        }

        stage('Deploy to Minikube') {
            steps {
                bat 'minikube profile list'
                bat "kubectl config use-context %CONTEXT%"
                bat "kubectl apply -f deployment.yaml"
            }
        }

        stage('Wait for Pod Ready') {
            steps {
                bat "kubectl wait --for=condition=ready pod -l app=flask-hello --timeout=60s"                
            }
        }        

        stage('Performance Test') {
            steps {
                bat 'call performance-test.bat'
            }
        }
    }

    post {
        always {
            echo 'Cleaning up deployment and service...'            
            bat 'kubectl delete deployment flask-hello --ignore-not-found'
            bat 'kubectl delete service flask-hello-service --ignore-not-found'
        }
    }
}