# # OIDC Provider for GitHub Actions
# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# }

# # IAM Role for GitHub Actions
# resource "aws_iam_role" "github_actions" {
#   name = "github-actions-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github_actions.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           }
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
#           }
#         }
#       }
#     ]
#   })

#   tags = var.tags
# }

# # IAM Policy for GitHub Actions
# resource "aws_iam_policy" "github_actions" {
#   name        = "github-actions-policy"
#   description = "Policy for GitHub Actions to deploy Kubeflow on EKS"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "eks:UpdateClusterConfig",
#           "eks:DescribeUpdate"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeVpcs",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeRouteTables",
#           "ec2:DescribeInternetGateways",
#           "ec2:DescribeNatGateways"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:ListBucket",
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           aws_s3_bucket.kubeflow_pipelines.arn,
#           "${aws_s3_bucket.kubeflow_pipelines.arn}/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "iam:GetRole",
#           "iam:PassRole",
#           "iam:ListRolePolicies",
#           "iam:ListAttachedRolePolicies",
#           "iam:GetRolePolicy",
#           "iam:GetPolicy",
#           "iam:GetPolicyVersion"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Attach policy to role
# resource "aws_iam_role_policy_attachment" "github_actions" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = aws_iam_policy.github_actions.arn
# }

# # Output the GitHub Actions role ARN
# output "github_actions_role_arn" {
#   description = "ARN of the IAM role for GitHub Actions"
#   value       = aws_iam_role.github_actions.arn
# }
