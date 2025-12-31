provider "aws" {
  region = var.aws_region
}

# -----------------------------
# IAM ROLE FOR EKS CLUSTER
# -----------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-role-tf-new2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -----------------------------
# VPC & SUBNET DATA
# -----------------------------
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

# -----------------------------
# EKS CLUSTER
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids = data.aws_subnets.default_subnets.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# -----------------------------
# IAM ROLE FOR NODE GROUP
# -----------------------------
resource "aws_iam_role" "eks_cluster_node_role" {
  name = "eks-role-tf2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEC2_ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_cluster_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "Amazon_EKS_CNI_Policy" {
  role       = aws_iam_role.eks_cluster_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_WorkerNodePolicy" {
  role       = aws_iam_role.eks_cluster_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# -----------------------------
# NODE GROUP
# -----------------------------
resource "aws_eks_node_group" "eks_node" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-nodes"
  node_role_arn   = aws_iam_role.eks_cluster_node_role.arn
  subnet_ids      = data.aws_subnets.default_subnets.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEC2_ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.Amazon_EKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKS_WorkerNodePolicy
  ]
}


#  EKS ACCESS ENTRY (ADMIN)

resource "aws_eks_access_entry" "eks_admin_user" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::753968716324:user/pranit"

  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_admin_user_policy" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.eks_admin_user.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
