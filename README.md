# 🚀 Flask App on AWS EKS with ALB, OAuth2 (GitHub), Helm & ArgoCD

## 📌 Overview

This project deploys a **Flask web application** on **AWS EKS** using:

- Terraform (Infrastructure as Code)
- Docker (Containerization)
- Helm (Kubernetes packaging)
- AWS Load Balancer Controller (ALB Ingress)
- oauth2-proxy (GitHub OAuth2 authentication)
- ACM (HTTPS certificate)
- Namecheap (paid domain,and DNS)
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
- NAT
- Internet gateway
- Security groups
- ECR
- Bastion Host
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
apiVersion: v1
kind: Secret
metadata:
  name: oauth2-proxy-secret
  namespace: default   
type: Opaque
stringData:
  client-id: {{ .values.client-id}}
  client-secret: {{ .values.client-secret}}
  cookie-secret: {{ .values.cookie-secret}}
```
## 4️⃣ Create OAuth2 Deployment and service

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oauth2-proxy
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oauth2-proxy
  template:
    metadata:
      labels:
        app: oauth2-proxy
    spec:
      containers:
      - name: oauth2-proxy
        image: quay.io/oauth2-proxy/oauth2-proxy:v7.6.0
        args:
          - --provider=github
          - --http-address=0.0.0.0:4180

          # ✅  protect everything by making oauth2-proxy the front door
          - --upstream=http://flask-service.default.svc.cluster.local:80

          # ✅  your domain
          - --redirect-url=https://mariam-flask.website/oauth2/callback
          - --whitelist-domain=mariam-flask.website

          # ✅  cookies
          - --cookie-secure=true
          - --cookie-httponly=true
          - --cookie-samesite=lax

          # optional but helpful
          - --email-domain=*
          - --set-authorization-header=true
          - --pass-access-token=true
          - --reverse-proxy=true
        env:
          - name: OAUTH2_PROXY_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: oauth2-proxy-secret
                key: client-id
          - name: OAUTH2_PROXY_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: oauth2-proxy-secret
                key: client-secret
          - name: OAUTH2_PROXY_COOKIE_SECRET
            valueFrom:
              secretKeyRef:
                name: oauth2-proxy-secret
                key: cookie-secret
        ports:
          - containerPort: 4180
```
```bash
apiVersion: v1
kind: Service
metadata:
  name: oauth2-proxy
  namespace: default
spec:
  selector:
    app: oauth2-proxy
  ports:
    - name: http
      port: 4180
      targetPort: 4180
```
---

## 🌐 Ingress (ALB)
The ALB Ingress:

- Terminates HTTPS
- Uses ACM certificate
- Routes traffic to oauth2-proxy
- oauth2-proxy forwards requests to Flask

Ingress ALB Annotations:
```bash
   kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn:<ACM_CERT_ARN>
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
- AWS Public Cloud
- Kubernetes ALB Ingress
- OAuth2 integration without Cognito
- Secure secret management
- GitOps workflow with ArgoCD

## 🎥 Application Demo Video
https://github.com/user-attachments/assets/a32a203f-bb08-44b8-a942-5ff0d086fbd0

---
## <img src="https://argo-cd.readthedocs.io/en/stable/assets/logo.png" width="40"/> ArgoCD UI with the Flask App
<img width="1857" height="980" alt="ArgoCD" src="https://github.com/user-attachments/assets/c1e98bb5-619d-4abf-832a-97a95d1ef60f" />

---

