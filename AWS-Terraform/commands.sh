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

