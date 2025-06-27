# Create namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/part-of" = "monitoring"
    }
  }
  depends_on = [module.eks]
}

# Helm release for Prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "19.6.1"

  set {
    name  = "server.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "server.persistentVolume.size"
    value = "20Gi"
  }

  set {
    name  = "server.retention"
    value = "15d"
  }

  set {
    name  = "alertmanager.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.persistentVolume.size"
    value = "10Gi"
  }

  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  set {
    name  = "pushgateway.enabled"
    value = "true"
  }

  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    helm_release.aws_ebs_csi_driver
  ]
}

# Helm release for Grafana
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "6.56.6"

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  set {
    name  = "adminPassword"
    value = "admin"  # In production, use a secret manager or a more secure approach
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.monitoring.svc.cluster.local"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    helm_release.prometheus,
    helm_release.aws_ebs_csi_driver
  ]
}

# Ingress for Grafana
resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port"     = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/api/health"
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
              name = "grafana"
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
    kubernetes_namespace.monitoring,
    helm_release.grafana,
    helm_release.aws_load_balancer_controller
  ]
}

# CloudWatch Container Insights
resource "helm_release" "cloudwatch_agent" {
  name       = "cloudwatch-agent"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  namespace  = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  version    = "0.0.9"

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
    value = kubernetes_service_account.cloudwatch_agent.metadata[0].name
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.amazon_cloudwatch,
    kubernetes_service_account.cloudwatch_agent
  ]
}

# Output the Grafana URL
output "grafana_url" {
  description = "URL for Grafana dashboard"
  value       = "http://${kubernetes_ingress_v1.grafana.status.0.load_balancer.0.ingress.0.hostname}"
}
