# provider
variable "aws-region" {}


#vpc
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "gw_name" {}


#subnets
variable "subnet_cidr" {
  type = list(any)
}
variable "subnet_name" {
  type = list(any)
}
variable "az" {
  type = list(any)
}


#nat
variable "nat_name" {}


# # lb security groupe
# variable "lb-ec2-cidr" {
#   type = list
# }

# # endpoint security group
# variable "endpoint-ssh-cidr" {
#   type = list
# }


#public rt
variable "pub-wanted-cidr" {}
variable "pub-table-name" {}

#private rt
variable "pri-wanted-cidr" {}
variable "pri-table-name" {}

#eks-cluster
variable "cluster_name" {}
variable "node_group_name" {}

variable "elb-type" {}
