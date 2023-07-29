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
  values           = var.values

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
    type  = "string"
  }

  depends_on = [kubernetes_namespace.argocd]
}
