module "terraform_vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  gw_name  = var.gw_name
}

module "terraform_subnet" {
  source         = "./modules/subnet"
  created_vpc_id = module.terraform_vpc.vpc_id
  subnet_cidr    = var.subnet_cidr
  az             = var.az
  subnet_name    = var.subnet_name
}

module "nat_gateway" {
  source           = "./modules/nat"
  public_subnet_id = module.terraform_subnet.first_pub_id
  nat_name         = var.nat_name
}

module "eks_nodes_security_group" {
  source         = "./modules/security-group"
  created_vpc_id = module.terraform_vpc.vpc_id

  ingress_rules = {
    connect = {
      port           = 443
      protocol       = "tcp"
      cidr_blocks    = []
      security_group = [module.bastion_host_security_group.sg_id]
    }
  }

  egress_rules = {
    all = {
      port           = 0
      protocol       = "-1"
      cidr_blocks    = ["0.0.0.0/0"]
      security_group = []
    }
  }

  sc_g_name = "eks_nodes_security_group"
}



module "bastion_host_security_group" {
  source         = "./modules/security-group"
  created_vpc_id = module.terraform_vpc.vpc_id

  ingress_rules = {
    ssh = {
      port           = 22
      protocol       = "tcp"
      cidr_blocks    = ["0.0.0.0/0"] #only my public ip
      security_group = []
    }
  }

  egress_rules = {
    no-rules = {
      port           = 0
      protocol       = "-1"
      cidr_blocks    = ["0.0.0.0/0"]
      security_group = []

    }
  }

  sc_g_name = "bastion_host_security_group"
}



module "public_routing_table" {
  source         = "./modules/route_table"
  created_vpc_id = module.terraform_vpc.vpc_id
  wanted_cidr    = var.pub-wanted-cidr
  needed_gatway  = module.terraform_vpc.internet_gateway_id
  table_name     = var.pub-table-name
  chosen_subnets = [module.terraform_subnet.first_pub_id, module.terraform_subnet.second_pub_id]
}


module "private_routing_table" {
  source         = "./modules/route_table"
  created_vpc_id = module.terraform_vpc.vpc_id
  wanted_cidr    = var.pri-wanted-cidr
  needed_gatway  = module.nat_gateway.nat_id
  table_name     = var.pri-table-name
  chosen_subnets = [module.terraform_subnet.first_pri_id, module.terraform_subnet.second_pri_id]
}


# module "eks-cloudwatch" {
#   source = "./modules/EKS/EKS-cloud-watch"
#   cluster_name = var.cluster_name
#   depends_on = [ module.eks-cluster ]
# }
module "eks-iam-roles" {
  source = "./modules/EKS/iam-roles"
}

module "EKS-cluster" {
  source                 = "./modules/EKS/cluster-master"
  cluster_name           = var.cluster_name
  eks-role               = module.eks-iam-roles.master-role-arn
  subnet_ids             = [module.terraform_subnet.first_pri_id, module.terraform_subnet.second_pri_id]
  cluster-security-group = [module.eks_nodes_security_group.sg_id]
  depends_on             = [module.eks-iam-roles]
}

module "EKS-node_group" {
  source          = "./modules/EKS/eks-node-group"
  cluster_name    = module.EKS-cluster.eks-cluster-name
  node_group_name = var.node_group_name
  node_role_arn   = module.eks-iam-roles.node-group-role-arn
  subnet_ids      = [module.terraform_subnet.first_pri_id, module.terraform_subnet.second_pri_id]
  key_name        = module.bastion-host.ssh_key_name
  depends_on      = [module.eks-iam-roles]
}


module "bastion-host" {
  source                      = "./modules/ec2-bastion-host"
  pub_subnet                  = module.terraform_subnet.second_pub_id
  bastion-host-security-group = [module.bastion_host_security_group.sg_id]
}

module "ecr_registry" {
  source = "./modules/ECR"
}




resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# Attach the IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}


data "aws_eks_cluster" "this" {
  name = module.EKS-cluster.eks-cluster-name
  depends_on = [ module.EKS-cluster ]
}

# data "aws_iam_openid_connect_provider" "eks" {
#   url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
# }

resource "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd40f7a"]
}


resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy required for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "ec2:GetSecurityGroupsForVpc"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:*"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListServerCertificates",
          "iam:GetServerCertificate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "waf-regional:GetWebACLForResource",
          "waf-regional:GetWebACL",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetWebACLForResource",
          "wafv2:GetWebACL",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DeleteProtection",
          "shield:CreateProtection",
          "shield:DescribeSubscription",
          "shield:ListProtections"
        ]
        Resource = "*"
      }
    ]
  })
}
