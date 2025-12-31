provider "aws" {
    region = var.aws_region
  
}

# IAM Role of EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-role-tf-new2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "eks.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# Roll attachment to eks cluster
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


# Data block for default vpc and subnet

data "aws_vpc" "default_vpc" {
    default = true 
  
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
}


# Cluster 

resource "aws_eks_cluster" "eks_cluster" {
  name = "my-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version
  
  vpc_config {
  subnet_ids = data.aws_subnets.default_subnets.ids
}


  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}


# IAM role for Node Group 

resource "aws_iam_role" "eks_cluster_node_role" {
  name = "eks-role-tf2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Roll attachment to eks node group 
resource "aws_iam_role_policy_attachment" "AmazonEC2_ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_node_role.name
}

resource "aws_iam_role_policy_attachment" "Amazon_EKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_WorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_node_role.name
}

# Node Group 

resource "aws_eks_node_group" "eks_node" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-nodes"
  node_role_arn   = aws_iam_role.eks_cluster_node_role.arn
  subnet_ids = data.aws_subnets.default_subnets.ids
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEC2_ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.Amazon_EKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKS_WorkerNodePolicy,
  ]
}