# Create Kubeflow namespace
resource "kubernetes_namespace" "kubeflow" {
  metadata {
    name = "kubeflow"
    labels = {
      "app.kubernetes.io/part-of" = "kubeflow"
    }
  }
  depends_on = [module.eks]
}

# Service account for Kubeflow Pipelines
resource "kubernetes_service_account" "pipeline_runner" {
  metadata {
    name      = "pipeline-runner"
    namespace = kubernetes_namespace.kubeflow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.kubeflow_pipelines_irsa.iam_role_arn
    }
  }
  depends_on = [module.eks, kubernetes_namespace.kubeflow]
}

# Helm release for Kubeflow Pipelines
resource "helm_release" "kubeflow_pipelines" {
  name       = "kubeflow-pipelines"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "kubeflow-pipelines"
  namespace  = kubernetes_namespace.kubeflow.metadata[0].name
  version    = var.kubeflow_version
  timeout    = 1200

  set {
    name  = "serviceAccountName"
    value = kubernetes_service_account.pipeline_runner.metadata[0].name
  }

  set {
    name  = "minio.enabled"
    value = "false"
  }

  set {
    name  = "s3.enabled"
    value = "true"
  }

  set {
    name  = "s3.bucket"
    value = aws_s3_bucket.kubeflow_pipelines.bucket
  }

  set {
    name  = "s3.region"
    value = var.region
  }

  set {
    name  = "s3.useSSL"
    value = "true"
  }

  set {
    name  = "executor.imagePullPolicy"
    value = "Always"
  }

  set {
    name  = "ui.serviceType"
    value = "ClusterIP"
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.kubeflow,
    kubernetes_service_account.pipeline_runner,
    aws_s3_bucket.kubeflow_pipelines,
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

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

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

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns.metadata[0].name
  }

  set {
    name  = "policy"
    value = "sync"
  }

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

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = kubernetes_service_account.cluster_autoscaler.metadata[0].name
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.expander"
    value = "least-waste"
  }

  depends_on = [
    module.eks,
    kubernetes_service_account.cluster_autoscaler
  ]
}

# Ingress for Kubeflow Pipelines UI
resource "kubernetes_ingress_v1" "kubeflow_pipelines" {
  metadata {
    name      = "kubeflow-pipelines-ingress"
    namespace = kubernetes_namespace.kubeflow.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port"     = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "ml-pipeline-ui"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.kubeflow,
    helm_release.kubeflow_pipelines,
    helm_release.aws_load_balancer_controller
  ]
}

# Output the Kubeflow Pipelines UI URL
output "kubeflow_pipelines_url" {
  description = "URL for Kubeflow Pipelines UI"
  value       = "http://${kubernetes_ingress_v1.kubeflow_pipelines.status.0.load_balancer.0.ingress.0.hostname}"
}
