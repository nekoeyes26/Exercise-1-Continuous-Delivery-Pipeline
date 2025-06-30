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
                bat "docker build -t %IMAGE_NAME%:%TAG% ."
            }
        }

        stage('Load Image to Minikube') {
            steps {
                bat "minikube -p %PROFILE% image load %IMAGE_NAME%:%TAG%"
            }
        }

        stage('Deploy to Minikube') {
            steps {
                bat "kubectl config use-context %CONTEXT%"
                bat "kubectl apply -f deployment.yaml"
            }
        }

        stage('Wait for Pod Ready') {
            steps {
                bat "kubectl wait --for=condition=ready pod -l app=flask-hello --timeout=60s"
                bat "for /f \"delims=\" %i in ('kubectl get pods -l app=flask-hello -o=jsonpath=\"{.items[0].metadata.name}\"') do kubectl logs %i"
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