# 🚀 CI/CD Pipeline for a React Application on AWS EKS

This project demonstrates a comprehensive DevOps solution for deploying a **React application** to a production-ready environment. It establishes a complete **CI/CD pipeline** using **Jenkins** to build, test, and deploy the application to an **AWS EKS (Elastic Kubernetes Service)** cluster.

Infrastructure is defined using **Terraform**, and monitoring is handled using **Prometheus** and **Grafana**.

---

## 📚 Table of Contents

1. [Project Architecture](#1-project-architecture)  
2. [Prerequisites](#2-prerequisites)  
3. [Phase 1: Infrastructure Setup with Terraform](#3-phase-1-infrastructure-setup-with-terraform)  
4. [Phase 2: Jenkins Configuration](#4-phase-2-jenkins-configuration)  
5. [Phase 3: CI/CD Pipeline and Manifests](#5-phase-3-cicd-pipeline-and-manifests)  
6. [Phase 4: Monitoring with Prometheus and Grafana](#6-phase-4-monitoring-with-prometheus-and-grafana)  
7. [Usage and Triggering a Build](#7-usage-and-triggering-a-build)  
8. [Cleanup](#8-cleanup)  

---

## 1️⃣ Project Architecture

The automated software delivery pipeline performs the following steps:

1. Developer pushes code to GitHub.
2. GitHub webhook triggers Jenkins.
3. Jenkins:
   - Checks out code
   - Builds Docker image
   - Pushes image to DockerHub
   - Deploys to EKS using `kubectl`
4. AWS Load Balancer exposes the app publicly.
5. Prometheus and Grafana monitor app and cluster health.

---

## 2️⃣ Prerequisites

You will need:

- ✅ **AWS Account** (admin access)
- ✅ **GitHub Repository** (for your app)
- ✅ **DockerHub Account**
- ✅ Installed tools:
  - [Terraform](https://developer.hashicorp.com/terraform/downloads)
  - [eksctl](https://eksctl.io/) → `brew install eksctl`
  - [aws-cli](https://aws.amazon.com/cli/) → `brew install awscli`
  - [kubectl](https://kubernetes.io/docs/tasks/tools/) → `brew install kubectl`
  - [Docker](https://www.docker.com/)

---

## 3️⃣ Phase 1: Infrastructure Setup with Terraform

1. Clone this repository and go to the `terraform/` directory:
   ```bash
   cd terraform/

2. Initialize and apply the infrastructure:
  ```bash
terraform init
terraform plan
terraform apply

```
3. SSH into the Jenkins EC2 instance:
  ``` CMD
ssh -i "your_key.pem" ubuntu@<JENKINS_PUBLIC_IP>
```
4. Configure kubectl on Jenkins:
   ``` bash
   aws eks update-kubeconfig --region <YOUR_AWS_REGION> --name <YOUR_EKS_CLUSTER_NAME>```

##4️⃣ Phase 2: Jenkins Configuration
#🔗 Access Jenkins:

Open your browser:
http://<JENKINS_PUBLIC_IP>:8080

🔌 Install Plugins:
Go to Manage Jenkins > Manage Plugins and install:

    GitHub Integration

    Docker

    Pipeline: Stage View

🔐 Add DockerHub Credentials:
1. Go to: Manage Jenkins > Credentials > Global > Add Credentials

2. Set:

    Kind: Username with password

    ID: dockerhub_credentials (must match Jenkinsfile)

    Username: your DockerHub username

    Password: your DockerHub password
   
🧪 Create a Jenkins Pipeline Job:

    Go to New Item → Pipeline

    Name: Trend-App-CI-CD

    Under Build Triggers: check ✅ GitHub hook trigger for GITScm polling

    Under Pipeline:

        Definition: Pipeline script from SCM

        SCM: Git

        Repo URL: https://github.com/PranuthHM/React_Application_Deployment_Document_2_Trend.git
Branch Specifier: */main


##5️⃣ Phase 3: CI/CD Pipeline and Manifests

Ensure the following files exist at the root of your GitHub repo:

    Jenkinsfile

    deployment.yaml

    service.yaml

⚙️ Jenkinsfile

``` 
pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "pranuthhm/trend-react-app"
        DOCKERHUB_CREDENTIALS = "dockerhub_credentials"
    }
    stages {
        stage('Git Checkout') {
            steps {
                echo "Checking out code from Git..."
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    sh "docker build -t ${DOCKER_IMAGE}:${gitCommit} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh "echo ${DOCKER_PASS} | docker login --username ${DOCKER_USER} --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                        sh "docker push ${DOCKER_IMAGE}:${gitCommit}"
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=/var/lib/jenkins/.kube/config
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                """
            }
        }
    }
}
```
🧱 deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trend-app-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: trend-app
  template:
    metadata:
      labels:
        app: trend-app
    spec:
      containers:
      - name: trend-app
        image: pranuthhm/trend-react-app:latest
        ports:
        - containerPort: 3000
```

🌐 service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: trend-app-service
spec:
  type: LoadBalancer
  selector:
    app: trend-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
```

##6️⃣ Phase 4: Monitoring with Prometheus and Grafana
🧰 Install Helm on Jenkins:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

📈 Deploy Monitoring Stack:

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.service.type=LoadBalancer \
  --set grafana.service.port=80 \
  --set grafana.service.targetPort=3000
```
🔗 Access Grafana:
```
kubectl get services -n monitoring
```
Open the EXTERNAL-IP of the prometheus-grafana service in browser.

Username: admin

Password: prom-operator

##7️⃣ Usage and Triggering a Build
To trigger a pipeline:

    Make a change in your application code.

    Push changes:
    git add .
    git commit -m "Update app"
    git push origin main

  Jenkins will:

    Pull the latest code

    Build Docker image

    Push it to DockerHub

    Deploy to Kubernetes via EKS

##8️⃣ Cleanup
To avoid AWS billing, destroy all created infrastructure.
🧹 Delete Kubernetes Resources:
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
helm uninstall prometheus --namespace monitoring
kubectl delete namespace monitoring

🧨 Destroy Terraform Resources:

From your local machine:

cd terraform/
terraform destroy

