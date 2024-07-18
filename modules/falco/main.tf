resource "kubernetes_namespace" "falco" {
  metadata {
    name = "falco"
  }
}

resource "helm_release" "falco" {
  depends_on = [kubernetes_namespace.falco]
  name       = "falco"
  namespace  = "falco"
  chart      = "falco"
  repository = "https://falcosecurity.github.io/charts"
  timeout    = 600
  version    = "4.0.0"
  values = [
    templatefile("${path.module}/config/values.yaml", {
      slack_webhook = var.slack_webhook
    })
  ]
}
