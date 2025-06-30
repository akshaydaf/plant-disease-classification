# Kubeflow on AWS EKS Infrastructure

This directory contains Terraform code to deploy Kubeflow Pipelines on AWS EKS with all the necessary infrastructure components.

## Architecture

The infrastructure includes:

- **VPC**: A dedicated VPC with public and private subnets across 2 availability zones
- **EKS**: Amazon Elastic Kubernetes Service cluster with managed node groups
- **S3**: S3 bucket for Kubeflow Pipelines artifacts
- **IRSA**: IAM Roles for Service Accounts for secure pod-level permissions
- **Ingress**: AWS Load Balancer Controller for ingress management
- **Observability**: Prometheus and Grafana for monitoring and visualization
- **Security**: KMS encryption, private subnets, security groups, and least privilege IAM policies

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0.0)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for interacting with the Kubernetes cluster

## Usage

### Manual Deployment

1. Initialize Terraform:

```bash
terraform init
```

2. Review the deployment plan:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. After deployment, configure kubectl to connect to your cluster:

```bash
aws eks update-kubeconfig --name kubeflow-eks --region us-east-1
```

### GitHub Actions Deployment

This infrastructure can also be deployed using the GitHub Actions workflow defined in `.github/workflows/terraform.yml`. The workflow will:

1. Run Terraform format, init, validate, and plan on pull requests
2. Apply the Terraform configuration when changes are merged to the main branch
3. Verify the Kubeflow deployment after the infrastructure is provisioned

To use GitHub Actions for deployment:

1. Set up the following secrets in your GitHub repository:

   - `AWS_ROLE_TO_ASSUME`: ARN of the IAM role for GitHub Actions to assume
   - `TF_API_TOKEN`: Terraform Cloud API token (if using Terraform Cloud)

2. Push changes to the infrastructure code to trigger the workflow

## Customization

You can customize the deployment by modifying the variables in `variables.tf`. The most common variables to adjust include:

- `region`: AWS region to deploy to (default: us-east-1)
- `cluster_name`: Name of the EKS cluster (default: kubeflow-eks)
- `cluster_version`: Kubernetes version to use (default: 1.28)
- `node_instance_types`: EC2 instance types for the node group (default: t3.medium)
- `node_desired_capacity`: Desired number of nodes (default: 2)
- `github_repo`: GitHub repository for OIDC provider (default: owner/repo)

## Accessing Kubeflow Pipelines

After deployment, you can access the Kubeflow Pipelines UI through the ALB endpoint. The URL will be output at the end of the Terraform apply:

```
kubeflow_pipelines_url = "http://<alb-endpoint>"
```

## Accessing Grafana

Grafana is deployed for monitoring and can be accessed through its ALB endpoint:

```
grafana_url = "http://<alb-endpoint>"
```

Default credentials:

- Username: admin
- Password: admin (change this after first login)

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```

## Security Considerations

This infrastructure is set up with security best practices in mind:

- EKS control plane logs are enabled and sent to CloudWatch
- All S3 buckets have encryption enabled
- Private subnets are used for EKS nodes
- IRSA is used for pod-level permissions
- Security groups are configured with least privilege access
- KMS keys are used for encryption

## Troubleshooting

If you encounter issues:

1. Check the CloudWatch logs for the EKS cluster
2. Verify the status of the Kubernetes pods:

```bash
kubectl get pods --all-namespaces
```

3. Check the status of the Helm releases:

```bash
helm list --all-namespaces
```

4. Review the Terraform state:

```bash
terraform state list
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
