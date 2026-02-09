aws configure

aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster


curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin

eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster my-eks-cluster \
  --approve
  #it connects your EKS cluster to AWS IAM using OIDC so that Kubernetes pods can securely use AWS permissions.
  # Creates an OIDC identity provider in IAM
  # Links it to your EKS cluster
  # Enables IAM Roles for Service Accounts (IRSA)
  # IRSA = IAM Roles for Service Accounts

eksctl create iamserviceaccount \
  --cluster my-eks-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::453979066708:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region us-east-1



eksctl create iamserviceaccount \
  --cluster my-eks-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::453979066708:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region us-east-1 \
  --override-existing-serviceaccounts




helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-095b5ed8ed64f72ae
