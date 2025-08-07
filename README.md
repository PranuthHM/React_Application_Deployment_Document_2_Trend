# 🚀 CI/CD Pipeline for a React Application on AWS EKS

This project demonstrates a comprehensive **DevOps solution** for deploying a React application to a production-ready environment. It sets up a **complete CI/CD pipeline** using **Jenkins** to build, test, and deploy the application to an **AWS EKS (Elastic Kubernetes Service)** cluster.

The entire infrastructure is defined using **Terraform**, and the deployed application is monitored using **Prometheus and Grafana**.

---

## 📚 Table of Contents

- [1️⃣ Project Architecture](#1️⃣-project-architecture)
- [2️⃣ Prerequisites](#2️⃣-prerequisites)
- [3️⃣ Step 1: Local Project Setup](#3️⃣-step-1-local-project-setup)
- [4️⃣ Step 2: Dockerize the Application](#4️⃣-step-2-dockerize-the-application)
- [5️⃣ Step 3: Terraform Infrastructure](#5️⃣-step-3-terraform-infrastructure)
- [6️⃣ Step 4: Jenkins Setup and Configuration](#6️⃣-step-4-jenkins-setup-and-configuration)
- [7️⃣ Step 5: DockerHub Repository](#7️⃣-step-5-dockerhub-repository)
- [8️⃣ Step 6: Kubernetes Setup (AWS EKS)](#8️⃣-step-6-kubernetes-setup-aws-eks)
- [9️⃣ Step 7: Kubernetes Deployment Manifests](#9️⃣-step-7-kubernetes-deployment-manifests)
- [🔟 Step 8: Jenkins CI/CD Pipeline](#🔟-step-8-jenkins-cicd-pipeline)
- [1️⃣1️⃣ Step 9: Monitoring with Prometheus and Grafana](#1️⃣1️⃣-step-9-monitoring-with-prometheus-and-grafana)
- [🧹 Cleanup](#🧹-cleanup)

---

## 1️⃣ Project Architecture

The pipeline automates the entire software delivery lifecycle:

1. A developer pushes code to **GitHub**.
2. A **GitHub webhook** triggers a **Jenkins** pipeline.
3. Jenkins:
   - Checks out the latest code.
   - Builds a **Docker** image.
   - Pushes the image to **DockerHub**.
   - Deploys the app to **AWS EKS** using `kubectl`.
4. An **AWS Load Balancer** is provisioned to expose the application publicly.
5. A **Prometheus + Grafana stack** is deployed on EKS for **real-time monitoring**.

---

## 2️⃣ Prerequisites

You will need the following:

- ✅ **AWS Account** with administrative access
- ✅ **GitHub Repository** (forked from this project)
- ✅ **DockerHub Account** to store your images
- ✅ Install the following tools:
  - [Terraform](https://developer.hashicorp.com/terraform/downloads)
  - [eksctl](https://eksctl.io/)  
  - [aws-cli](https://docs.aws.amazon.com/cli/)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - [Docker](https://www.docker.com/)

---

## 3️⃣ Step 1: Local Project Setup
1. Clone the original repository and navigate into the folder:
```bash
git clone https://github.com/Vennilavan12/Trend.git
cd Trend
```

2. Set the new remote URL to your GitHub repository:
``` bash
git remote set-url origin https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>.git
git push -u origin main
```

3. Add .gitignore and .dockerignore files to the root of your project:
``` .gitignore
# Node modules
node_modules
.env
# Build artifacts
build
dist
*.log
# OS generated files
.DS_Store
.idea
.vscode
```

``` .dockerignore
node_modules
.git
.gitignore
Dockerfile
Jenkinsfile
README.md
.env
```

4. Commit and push the new files:
``` bash
git add .
git commit -m "Add .gitignore and .dockerignore files"
git push origin main
```
## 4️⃣ Step 2: Dockerize the Application
1. Create the Dockerfile in the root of your project:
``` bash
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist /usr/share/nginx/html
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
```

2. Create the nginx.conf file to serve the application:
``` bash
server {
    listen 3000;
    server_name localhost;
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

3. Build and test the Docker image locally (optional but recommended):
``` bash
docker build -t trend-react-app:latest .
docker run -d -p 3000:3000 --name trend-app-container trend-react-app:latest
# Visit http://localhost:3000 to test
docker stop trend-app-container && docker rm trend-app-container
```

4. Commit and push the Docker files:
``` bash
git add Dockerfile nginx.conf
git commit -m "Add Dockerfile and Nginx config for application deployment"
git push origin main
```

---

## 5️⃣ Step 3: Terraform Infrastructure

1. Create a new terraform directory in the root of your project and create a file named main.tf inside it.

2. Define your infrastructure in main.tf. Remember to replace <YOUR_UNIQUE_S3_BUCKET_NAME> with a unique S3 bucket name for state management.
``` CMD
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "your-unique-terraform-state-bucket" # ⚠️ REPLACE THIS
    key    = "devops-project/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}

# (VPC, Subnets, IGW, Route Table resources as provided in your notes)
# --- VPC and Subnet ---
resource "aws_vpc" "project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Project-VPC"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Project-Public-Subnet"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Project-Public-Subnet-2"
  }
}
resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "Project-IGW"
  }
}
resource "aws_route_table" "project_rt" {
  vpc_id = aws_vpc.project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }
  tags = {
    Name = "Project-RouteTable"
  }
}
resource "aws_route_table_association" "project_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.project_rt.id
}

# --- Security Group for Jenkins EC2 ---
resource "aws_security_group" "jenkins_sg" {
  vpc_id      = aws_vpc.project_vpc.id
  name        = "jenkins-ec2-sg"
  description = "Security group for Jenkins EC2 instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Jenkins-EC2-SG"
  }
}
# (IAM Role, Instance Profile, SSH Key Pair, and Jenkins EC2 Instance resources)
# --- IAM Role for Jenkins EC2 ---
resource "aws_iam_role" "ec2_instance_profile_role" {
  name = "ec2-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "EC2-Jenkins-Role"
  }
}
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-jenkins-instance-profile"
  role = aws_iam_role.ec2_instance_profile_role.name
}
# --- SSH Key Pair Generation ---
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private_key" {
  content         = tls_private_key.sshkey.private_key_pem
  filename        = "${path.module}/terraform_ssh_key.pem"
  file_permission = "0400"
}
resource "aws_key_pair" "generated" {
  key_name   = "terraform-jenkins-key"
  public_key = tls_private_key.sshkey.public_key_openssh
}
# --- Jenkins EC2 Instance ---
resource "aws_instance" "jenkins_ec2" {
  ami                   = "ami-00bb6a80f01f03502"
  instance_type         = "t3.medium"
  key_name              = aws_key_pair.generated.key_name
  subnet_id             = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y openjdk-17-jdk
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update -y
    sudo apt install -y jenkins
    sudo apt install -y docker.io
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    curl -LO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
    tar -xzf eksctl_Linux_amd64.tar.gz
    sudo mv eksctl /usr/local/bin
    sudo apt install awscli -y
  EOF
  tags = {
    Name = "Jenkins-EC2-Instance"
  }
}
output "jenkins_public_ip" {
  description = "The public IP address of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.public_ip
}
output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = "${path.module}/terraform_ssh_key.pem"
}
```

3. Run Terraform Commands:
``` CMD
terraform init
terraform plan -out tfplan
terraform apply "tfplan"
```

## 6️⃣ Step 4: Jenkins Setup and Configuration

1. Access Jenkins: Find the public IP from the Terraform output. Open http://<JENKINS_PUBLIC_IP>:8080.

2. Retrieve Initial Admin Password: SSH into the Jenkins instance and run:
``` bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

3. Install Plugins: Navigate to Manage Jenkins > Manage Plugins and install the following:

   a. GitHub Plugin

   b. Docker Pipeline

   c. Kubernetes CLI

4. Configure GitHub Webhook:
   a. In Jenkins, go to Manage Jenkins > Configure System and add a GitHub Server.

   b. In your GitHub repo, go to Settings > Webhooks > Add webhook.

   c. Payload URL: http://<YOUR_JENKINS_PUBLIC_IP>:8080/github-webhook/

   d. Content type: application/json

   e. Select Just the push event and ensure it's active.

5. Store DockerHub Credentials:
   a. In Jenkins, go to Manage Jenkins > Manage Credentials.

   b. Add a new credential of type Username with password.

   c. ID: dockerhub_credentials

   d. Enter your DockerHub username and password.

---

## 7️⃣ Step 5: DockerHub Repository

1. Log in to DockerHub.

2. Create a new repository with the name pranuthhm/trend-react-app (replace with your username).

3. Set the visibility to Public.

## 8️⃣ Step 6: Kubernetes Setup (AWS EKS)

1. Create cluster.yaml on your Jenkins server: Find the VPC and subnet IDs in the AWS Console.

``` YAML
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: my-trend-cluster
  region: ap-south-1
  version: "1.29"

vpc:
  id: <YOUR_VPC_ID>
  subnets:
    public:
      ap-south-1a:
        id: <YOUR_PUBLIC_SUBNET_ID>
      ap-south-1b:
        id: <YOUR_PUBLIC_SUBNET_2_ID>

managedNodeGroups:
  - name: my-trend-nodes
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
    volumeSize: 20 # GB
    ssh:
      allow: true
      publicKeyPath: /home/ubuntu/.ssh/id_rsa.pub # We will create this key next
```
2. Create the EKS Cluster:
``` bash
eksctl create cluster -f cluster.yaml
```
3. Verufy the Clusters:
``` bash
aws eks update-kubeconfig --region ap-south-1 --name my-trend-cluster
kubectl get nodes
```

---
## 9️⃣ Step 7: Kubernetes Deployment Manifests
Create the following files on your Jenkins EC2 instance in your project directory.

1. deployment.yaml
``` YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trend-app-deployment
  labels:
    app: trend-app
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
      - name: trend-app-container
        image: pranuthhm/trend-react-app:latest
        ports:
        - containerPort: 3000
```
2. service.yaml
``` YAML
apiVersion: v1
kind: Service
metadata:
  name: trend-app-service
  labels:
    app: trend-app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  selector:
    app: trend-app
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
```
---

🔟 Step 8: Jenkins CI/CD Pipeline

1. Create Jenkinsfile on your local machine in the root of your project:

```Groovy
pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "pranuthhm/trend-react-app"
        DOCKERHUB_CREDENTIALS = "dockerhub_credentials"
        KUBECONFIG_PATH = "/var/lib/jenkins/.kube/config"
    }
    stages {
        stage('Git Checkout') {
            steps {
                echo 'Checking out code from Git...'
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def gitHash = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    sh "docker build -t ${DOCKER_IMAGE}:${gitHash} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh "echo $DOCKER_PASS | docker login --username $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                        sh "docker push ${DOCKER_IMAGE}:${sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()}"
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=/var/lib/jenkins/.kube/config
                    echo "Applying Kubernetes Deployment..."
                    kubectl apply -f deployment.yaml
                    echo "Applying Kubernetes Service..."
                    kubectl apply -f service.yaml
                """
            }
        }
    }
}
```
2. Commit and push the Jenkinsfile and Kubernetes manifests to GitHub.

3. Trigger the Pipeline: Go to your Jenkins job and click Build Now. The pipeline will run, and upon completion, a Load Balancer will be provisioned.

4. Get the application URL by running kubectl get services on your Jenkins instance and copying the EXTERNAL-IP.

---

## 🔵 11. Step 9: Monitoring with Prometheus and Grafana
1. On your Jenkins instance, install Helm:

``` bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

2. Install the kube-prometheus-stack with a public Load Balancer for Grafana:

``` bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set grafana.service.type=LoadBalancer --set grafana.service.port=80 --set grafana.service.targetPort=3000
```

3. Get the Grafana URL from kubectl get services -n monitoring and use the following credentials to log in:

   a. Username: admin

   b. Password: prom-operator

---

## 🧹 Cleanup

1. Delete Kubernetes Services: On your Jenkins instance, delete the application and monitoring services.
``` bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
helm uninstall prometheus --namespace monitoring
kubectl delete namespace monitoring
```

2. Destroy Terraform Resources: On your local machine, run terraform destroy.
``` bash
terraform destroy
```
### For more reference please view document file 
<href> https://github.com/PranuthHM/Document_React_Application_Deployment_Document_2_Trend.git </href>
