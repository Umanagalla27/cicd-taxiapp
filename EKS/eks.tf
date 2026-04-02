terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

########################
# GET DEFAULT VPC
########################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name = "availability-zone"
    values = [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c"
    ]
  }
}

########################
# IAM ROLE FOR EKS CLUSTER
########################
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

########################
# IAM ROLE FOR NODES
########################
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy_1" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_policy_2" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_policy_3" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_access" {
  role       = data.aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

########################
# EKS CLUSTER
########################
resource "aws_eks_cluster" "eks" {
  name     = "taxi-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.eks_subnets.ids
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

data "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"
}

resource "aws_ec2_tag" "subnet_tags_eks" {
  for_each    = toset(data.aws_subnets.eks_subnets.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/taxi-eks-cluster"
  value       = "shared"
}

resource "aws_ec2_tag" "subnet_tags_elb" {
  for_each    = toset(data.aws_subnets.eks_subnets.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}


########################
# NODE GROUP
########################
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "taxi-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.eks_subnets.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium", "t3a.medium", "t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.node_policy_1,
    aws_iam_role_policy_attachment.node_policy_2,
    aws_iam_role_policy_attachment.node_policy_3
  ]
}

########################
# ACCESS ENTRY (FIXES UNAUTHORIZED)
########################
resource "aws_eks_access_entry" "jenkins_access" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = "arn:aws:iam::783476056561:role/jenkins-ec2-role"
  kubernetes_groups = ["taxi-admin"]
  type              = "STANDARD"
}

resource "aws_eks_access_entry" "admin_user_access" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = "arn:aws:iam::783476056561:user/TaxiApp-DevOps-Admin"
  kubernetes_groups = ["taxi-admin"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins_admin_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::783476056561:role/jenkins-ec2-role"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "admin_user_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::783476056561:user/TaxiApp-DevOps-Admin"

  access_scope {
    type = "cluster"
  }
}

########################
# OUTPUT
########################
output "cluster_name" {
  value = aws_eks_cluster.eks.name
}