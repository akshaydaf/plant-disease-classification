# Deploy Kubeflow using Kustomize with variable substitution
resource "null_resource" "kubeflow_kustomize" {
  triggers = {
    kustomization_hash = filemd5("${path.module}/kubeflow/deploy/kustomization.yaml")
    s3_bucket          = aws_s3_bucket.kubeflow_pipelines.bucket
    region             = var.region
    role_arn           = module.kubeflow_pipelines_irsa.iam_role_arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create temporary directory for processed manifests
      mkdir -p /tmp/kubeflow-deploy
      
      # Copy Kustomize files to temp directory
      cp -r ${path.module}/kubeflow/deploy/* /tmp/kubeflow-deploy/
      
      # Replace placeholders with actual values
      sed -i.bak 's/PLACEHOLDER_S3_BUCKET_NAME/${aws_s3_bucket.kubeflow_pipelines.bucket}/g' /tmp/kubeflow-deploy/s3-config.yaml
      sed -i.bak 's/PLACEHOLDER_AWS_REGION/${var.region}/g' /tmp/kubeflow-deploy/s3-config.yaml
      sed -i.bak 's|\$${PIPELINE_RUNNER_ROLE_ARN}|${module.kubeflow_pipelines_irsa.iam_role_arn}|g' /tmp/kubeflow-deploy/service-account.yaml
      
      # Apply the Kustomize configuration
      kubectl apply -k /tmp/kubeflow-deploy
      
      # Clean up
      rm -rf /tmp/kubeflow-deploy
    EOT
  }

  depends_on = [
    module.eks,
    aws_s3_bucket.kubeflow_pipelines,
    module.kubeflow_pipelines_irsa,
    helm_release.aws_load_balancer_controller
  ]
}

# Helm release for AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.3"

  set = [{
    name  = "clusterName"
    value = module.eks.cluster_name
    }, {
    name  = "serviceAccount.create"
    value = "false"
    }, {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    }, {
    name  = "region"
    value = var.region
    }, {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }]

  depends_on = [
    module.eks,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# Helm release for External DNS
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "6.20.4"

  set = [{
    name  = "provider"
    value = "aws"
    }, {
    name  = "aws.region"
    value = var.region
    }, {
    name  = "serviceAccount.create"
    value = "false"
    }, {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns.metadata[0].name
    }, {
    name  = "policy"
    value = "sync"
  }]

  depends_on = [
    module.eks,
    kubernetes_service_account.external_dns
  ]
}

# Helm release for Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.29.0"

  set = [{
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
    }, {
    name  = "awsRegion"
    value = var.region
    }, {
    name  = "rbac.serviceAccount.create"
    value = "false"
    }, {
    name  = "rbac.serviceAccount.name"
    value = kubernetes_service_account.cluster_autoscaler.metadata[0].name
    }, {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
    }, {
    name  = "extraArgs.expander"
    value = "least-waste"
  }]

  depends_on = [
    module.eks,
    kubernetes_service_account.cluster_autoscaler
  ]
}

# Output the Kubeflow Pipelines UI URL (will be available after deployment)
output "kubeflow_pipelines_url" {
  description = "URL for Kubeflow Pipelines UI - check AWS Load Balancer console for the actual URL after deployment"
  value       = "Kubeflow Pipelines will be available via the AWS Load Balancer created by the ingress"
}
