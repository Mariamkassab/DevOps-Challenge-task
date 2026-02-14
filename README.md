# 🚀 Flask App on AWS EKS with ALB, OAuth2 (GitHub), Helm & ArgoCD

## 📌 Overview

This project deploys a **Flask web application** on **AWS EKS** using:

- Terraform (Infrastructure as Code)
- Docker (Containerization)
- Helm (Kubernetes packaging)
- AWS Load Balancer Controller (ALB Ingress)
- oauth2-proxy (GitHub OAuth2 authentication)
- ACM (HTTPS certificate)
- ArgoCD (GitOps deployment)

The application is protected using **OAuth2 authentication via GitHub**.

---

# Authentication Architecture Diagram

```text
        ┌──────────────┐
        │     User     │
        └───────┬──────┘
                │
                ▼
        ┌────────────────────────┐
        │  ALB (HTTPS via ACM)   │
        └──────────┬─────────────┘
                   │
                   ▼
        ┌────────────────────────┐
        │ oauth2-proxy           │
        │ (GitHub OAuth2)        │
        └──────────┬─────────────┘
                   │
                   ▼
        ┌────────────────────────┐
        │   Flask Application    │
        └──────────┬─────────────┘
                   │
                   ▼
        ┌────────────────────────┐
        │      EKS Cluster       │
        └────────────────────────┘

```
---
###  https://mariam-flask.website
---

# ⚙️ Infrastructure (Terraform)

The following resources are provisioned:

- VPC
- Public & Private Subnets
- EKS Cluster
- IAM Roles (IRSA)
- AWS Load Balancer Controller
- ACM Certificate

## Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```
---

# 🐳 Docker

## 🔨 Build Image

```bash
docker build -t flask-app .
```

# 🚀 Tag & Push to ECR

```bash
docker tag flask-app:latest <ECR_REPO_URL>
docker push <ECR_REPO_URL>
```

# docker tag flask-app:latest <ECR_REPO_URL>
docker push <ECR_REPO_URL>

```bash
docker tag flask-app:latest <ECR_REPO_URL>
docker push <ECR_REPO_URL>
```

---

# 🔐 GitHub OAuth2 Setup

Authentication is handled by **oauth2-proxy**.

---

## 1️⃣ Create GitHub OAuth App

Go to:

**GitHub → Settings → Developer settings → OAuth Apps → New OAuth App**

---

### 🌐 Homepage URL

###  https://mariam-flask.website

---

### 🔁 Authorization Callback URL

### https://mariam-flask.website/oauth2/callback


---

### 📋 After Creating the App, Copy:

- Client ID  
- Client Secret  

You will use these values in your `oauth2-proxy` configuration.

## 2️⃣ Generate Cookie Secret

```bash
python3 - <<'PY'
import os,base64
print(base64.urlsafe_b64encode(os.urandom(32)).decode().rstrip("="))
PY
```
## 3️⃣ Create Kubernetes Secret
```bash
kubectl create secret generic oauth2-proxy-secret \
  -n default \
  --from-literal=client-id="<GITHUB_CLIENT_ID>" \
  --from-literal=client-secret="<GITHUB_CLIENT_SECRET>" \
  --from-literal=cookie-secret="<COOKIE_SECRET>"
```
## 🌐 Ingress (ALB)
The ALB Ingress:

- Terminates HTTPS
- Uses ACM certificate
- Routes traffic to oauth2-proxy
- oauth2-proxy forwards requests to Flask

Example annotations:
```bash
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
alb.ingress.kubernetes.io/ssl-redirect: "443"
```
## 🔒 HTTPS (ACM)
ACM certificate is requested and validated via DNS.

DNS is configured in Namecheap using:
```badh
CNAME → ALB DNS name
```
## 🚦 ArgoCD (GitOps)
ArgoCD is configured to:
- Sync the application from GitHub repository
- Automatically deploy Helm charts
- Manage Kubernetes resources declaratively
Login example:
```bash
argocd login <ARGOCD_DOMAIN>
```
## 🧪 Useful Commands

Check ingress:
```bash
kubectl get ingress
```
Check oauth2-proxy logs:
```bash
kubectl logs deployment/oauth2-proxy
```
Check service endpoints:
```bash
kubectl get endpoints
```
## 🛡️ Security

- HTTPS enforced
- OAuth2 authentication required
- Kubernetes Secrets used for credentials
- IAM Roles for Service Accounts (IRSA)
- No hardcoded secrets in repository

## 🧠 Technologies Used

- AWS EKS
- Terraform
- Docker
- Helm
- GitHub OAuth2
- oauth2-proxy
- AWS ACM
- ArgoCD
- Kubernetes

## 🎯 Learning Objectives

- This project demonstrates:
- Infrastructure as Code
- Kubernetes ALB Ingress
- OAuth2 integration without Cognito
- Secure secret management
- GitOps workflow with ArgoCD

## 🎥 Demo Video

https://github.com/Mariamkassab/DevOps-Challenge-task/Demo/Flask-Demo.mp4