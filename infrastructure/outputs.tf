# Output values for Kubeflow on AWS EKS

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "kubeflow_namespace" {
  description = "Namespace for Kubeflow"
  value       = kubernetes_namespace.kubeflow.metadata[0].name
}

output "monitoring_namespace" {
  description = "Namespace for monitoring"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "s3_bucket_id" {
  description = "The ID of the S3 bucket for Kubeflow Pipelines artifacts"
  value       = aws_s3_bucket.kubeflow_pipelines.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for Kubeflow Pipelines artifacts"
  value       = aws_s3_bucket.kubeflow_pipelines.arn
}

output "kubeflow_pipelines_role_arn" {
  description = "The ARN of the IAM role for Kubeflow Pipelines"
  value       = module.kubeflow_pipelines_irsa.iam_role_arn
}

output "load_balancer_controller_role_arn" {
  description = "The ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.load_balancer_controller_irsa.iam_role_arn
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role for External DNS"
  value       = module.external_dns_irsa.iam_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "The ARN of the IAM role for Cluster Autoscaler"
  value       = module.cluster_autoscaler_irsa.iam_role_arn
}

output "cloudwatch_metrics_role_arn" {
  description = "The ARN of the IAM role for CloudWatch Metrics"
  value       = module.cloudwatch_metrics_irsa.iam_role_arn
}

# output "github_actions_oidc_provider_arn" {
#   description = "The ARN of the OIDC Provider for GitHub Actions"
#   value       = aws_iam_openid_connect_provider.github_actions.arn
# }

output "github_actions_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "tags" {
  description = "A map of tags applied to resources"
  value       = var.tags
}
