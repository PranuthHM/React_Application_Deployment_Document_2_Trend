pipeline {
    agent any
    environment {
        // Replace with your DockerHub repository name
        DOCKER_IMAGE = "pranuthhm/trend-react-app"
        // The credentials ID for DockerHub stored in Jenkins
        DOCKERHUB_CREDENTIALS = "dockerhub_credentials"
        // Get Kubeconfig path. This is what was created by `aws eks update-kubeconfig`
        KUBECONFIG_PATH = "/home/ubuntu/.kube/config"
    }
    stages {
        stage('Git Checkout') {
            steps {
                // This is handled automatically by the Git plugin
                echo 'Checking out code from Git...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Get the current Git commit hash for tagging the image
                    def gitHash = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()

                    // Build the Docker image with the Git commit hash as a tag
                    sh "docker build -t ${DOCKER_IMAGE}:${gitHash} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        // Login to DockerHub
                        sh "echo $DOCKER_PASS | docker login --username $DOCKER_USER --password-stdin"

                        // Push the 'latest' and commit-tagged images to DockerHub
                        sh "docker push ${DOCKER_IMAGE}:latest"
                        sh "docker push ${DOCKER_IMAGE}:${sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()}"
                    }
                }
            }
        }

       // ... (rest of the pipeline remains the same)

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    # Configure kubectl to use the kubeconfig file on the Jenkins server
                    export KUBECONFIG=/home/ubuntu/.kube/config

                    # Apply the Kubernetes Deployment and Service manifests
                    echo "Applying Kubernetes Deployment..."
                    kubectl apply -f deployment.yaml
                    echo "Applying Kubernetes Service..."
                    kubectl apply -f service.yaml
                """
            }
        }
    }
}