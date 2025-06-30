pipeline {
    agent any

    environment {
        BUILD_TIMESTAMP = new Date().format("yyyyMMdd-HHmm")
        DOCKER_IMAGE = "aeonyx/hello-service"
        PROFILE = 'staging'
        CONTEXT = "${PROFILE}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Source code checked out automatically by SCM'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    bat "docker login -u %DOCKER_USER% -p %DOCKER_PASS%"
                    bat "docker build -t %DOCKER_IMAGE%:%BUILD_TIMESTAMP% ."
                    bat "docker push %DOCKER_IMAGE%:%BUILD_TIMESTAMP%"
                }
            }
        }

        stage('Update Image Version in deployment.yaml') {
            steps {
                bat "powershell -Command \"(Get-Content deployment.yaml).replace('{{VERSION}}', '%BUILD_TIMESTAMP%') | Set-Content deployment.yaml\""
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
