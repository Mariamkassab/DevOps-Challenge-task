aws configure

aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster


curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version


helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-0e09eec3038349893


aws iam get-role --role-name eks-alb-controller-role \
  --query "Role.Arn" --output text



kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::453979066708:role/eks-alb-controller-role
EOF


aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin 453979066708.dkr.ecr.us-east-1.amazonaws.com/app-reg


docker tag flask-docker-app:latest \
453979066708.dkr.ecr.us-east-1.amazonaws.com/app-reg:latest

docker push 453979066708.dkr.ecr.us-east-1.amazonaws.com/app-reg:latest


helm install flask-release .

kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# Check logs of the controller for your ingress

 


# ArgoCD installation 

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd

kubectl create namespace argocd

helm install argocd argo/argo-cd \
  -n argocd \
  -f argocd-values.yaml





# Helm Secrets or AWS Secrets Manager

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


helm plugin install https://github.com/jkroepke/helm-secrets   #install helm secrets
curl -L https://github.com/getsops/sops/releases/download/v3.8.1/sops-linux-amd64 -o sops #install sops
chmod +x sops
mv sops /usr/local/bin/sops


helm secrets encrypt ./templates/secret.yaml
helm secrets upgrade --install flask-app ./chart -f s./template/ecrets.yaml

kubectl get secret flask-secret -o yaml # we will see the encrypted version of the secret




