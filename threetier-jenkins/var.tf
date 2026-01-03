variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "demo-eks-cluster1"
}

variable "node_instance_type" {
  default = "t2.medium"
}

variable "desired_nodes" {
  default = 2
}