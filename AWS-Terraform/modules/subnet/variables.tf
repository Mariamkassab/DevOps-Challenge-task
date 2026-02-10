variable "created_vpc_id" {
    type = any
}

variable "subnet_cidr" {
    type = list  
}

variable "subnet_name" {
  type = list
}

variable "az" {
  type = list
}

variable "elb-type" {
  type = list
}

variable "cluster_name" {
  type = string
}