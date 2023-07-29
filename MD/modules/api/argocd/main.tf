resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name             = "argocd-${var.argocd_name}"
  repository       = var.helm_repo_url
  chart            = "argo-cd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = var.argocd_helm_chart_version == "" ? null : var.argocd_helm_chart_version

  values = [
    templatefile("values.yaml.tpl",
      {
        "argocd_ingress_enabled"          = var.argocd_ingress_enabled
        "argocd_ingress_class"            = "alb"
        "argocd_server_host"              = var.argocd_server_host
        "argocd_load_balancer_name"       = "${var.argocd_name}-alb-ingress"
        "argocd_ingress_tls_acme_enabled" = true
      }
    )
  ]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
    type  = "string"
  }

  depends_on = [kubernetes_namespace.argocd]
}
