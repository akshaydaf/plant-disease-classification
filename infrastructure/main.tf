# Main Terraform file for Kubeflow on AWS EKS

# Local variables
locals {
  cluster_name = var.cluster_name
  region       = var.region
  tags = merge(
    var.tags,
    {
      "terraform-module" = "kubeflow-on-aws"
      "terraform-region" = var.region
    }
  )
}

# Create a random ID for unique resource naming
resource "random_id" "this" {
  byte_length = 4
}

# Create a KMS key for EKS secrets encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

# Create a KMS alias for the EKS KMS key
resource "aws_kms_alias" "eks" {
  name          = "alias/eks-${local.cluster_name}"
  target_key_id = aws_kms_key.eks.key_id
}

# Create a KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "S3 Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

# Create a KMS alias for the S3 KMS key
resource "aws_kms_alias" "s3" {
  name          = "alias/s3-${local.cluster_name}"
  target_key_id = aws_kms_key.s3.key_id
}

# Create a security group for the EKS control plane
resource "aws_security_group" "control_plane" {
  name        = "${local.cluster_name}-control-plane"
  description = "Security group for EKS control plane"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.cluster_name}-control-plane"
    }
  )
}

# Create a security group for the EKS worker nodes
resource "aws_security_group" "worker_nodes" {
  name        = "${local.cluster_name}-worker-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.cluster_name}-worker-nodes"
    }
  )
}

# Allow the control plane to communicate with the worker nodes
resource "aws_security_group_rule" "control_plane_to_worker_nodes" {
  description              = "Allow control plane to communicate with worker nodes"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_nodes.id
  source_security_group_id = aws_security_group.control_plane.id
  type                     = "ingress"
}

# Allow the worker nodes to communicate with the control plane
resource "aws_security_group_rule" "worker_nodes_to_control_plane" {
  description              = "Allow worker nodes to communicate with control plane"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.control_plane.id
  source_security_group_id = aws_security_group.worker_nodes.id
  type                     = "ingress"
}

# Allow worker nodes to communicate with each other
resource "aws_security_group_rule" "worker_nodes_to_worker_nodes" {
  description              = "Allow worker nodes to communicate with each other"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_nodes.id
  source_security_group_id = aws_security_group.worker_nodes.id
  type                     = "ingress"
}
