# Kubeflow Deployment with Kustomize

This directory contains the Kustomize configuration for deploying Kubeflow Pipelines to your EKS cluster.

## Structure

```
kubeflow/
└── deploy/
    ├── kustomization.yaml    # Main Kustomize configuration
    ├── namespace.yaml        # Kubeflow namespace
    ├── service-account.yaml  # IRSA-enabled service account
    ├── s3-config.yaml       # S3 configuration for ML artifacts
    └── ingress.yaml         # HTTP ingress for web access
```

## What Each File Does

### `kustomization.yaml` (The Main Recipe)

- References the official Kubeflow Pipelines manifests from GitHub
- Applies our custom configurations and patches
- Pins specific image versions for stability

### `namespace.yaml` (The Container)

- Creates the `kubeflow` namespace where all components will live
- Keeps Kubeflow isolated from other applications

### `service-account.yaml` (The Identity Card)

- Creates a service account that can securely access AWS S3
- Uses IRSA (IAM Roles for Service Accounts) for secure AWS access
- No need to store AWS credentials in the cluster

### `s3-config.yaml` (The Storage Instructions)

- Configures Kubeflow to store ML artifacts in your S3 bucket
- Disables the default MinIO storage
- Sets up environment variables for S3 access

### `ingress.yaml` (The Front Door)

- Creates an AWS Application Load Balancer
- Provides HTTP access to the Kubeflow Pipelines UI
- No SSL/HTTPS (you can add this later with ACM if needed)

## How It Works

1. **Terraform** processes the placeholders in the YAML files
2. **Terraform** replaces them with actual values (S3 bucket name, AWS region, IAM role ARN)
3. **kubectl** applies the Kustomize configuration to your cluster
4. **Kustomize** downloads the official Kubeflow manifests and applies your customizations

## Benefits of This Approach

- **Official Support**: Uses the official Kubeflow Kustomize manifests
- **Easy Updates**: Can easily update to new Kubeflow versions
- **Customizable**: Easy to add your own patches and configurations
- **GitOps Ready**: All configurations are stored as code
- **Secure**: Uses IRSA for AWS access instead of storing credentials

## Accessing Kubeflow

After deployment, you can find the Kubeflow Pipelines UI URL by:

1. **Via kubectl**:

   ```bash
   kubectl get ingress -n kubeflow kubeflow-ingress
   ```

2. **Via AWS Console**:
   - Go to EC2 → Load Balancers
   - Find the load balancer created by the ingress
   - Use the DNS name to access Kubeflow

## Troubleshooting

### Check if pods are running:

```bash
kubectl get pods -n kubeflow
```

### Check ingress status:

```bash
kubectl describe ingress -n kubeflow kubeflow-ingress
```

### Check service account:

```bash
kubectl describe serviceaccount -n kubeflow pipeline-runner
```

### View logs:

```bash
kubectl logs -n kubeflow deployment/ml-pipeline-api-server
```
