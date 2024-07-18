
resource "kubernetes_namespace" "kube-clarity" {
  metadata {
    name = var.kubeclarity_namespace
  }
}

resource "random_password" "kube-clarity" {
  count   = var.kubeclarity_enabled ? 1 : 0
  length  = 20
  special = false
}

resource "kubernetes_secret" "kube-clarity" {
  depends_on = [kubernetes_namespace.kube-clarity]
  metadata {
    name      = "basic-auth"
    namespace = var.kubeclarity_namespace
  }

  data = {
    auth = "admin:${bcrypt(random_password.kube-clarity[0].result)}"
  }

  type = "Opaque"
}

resource "helm_release" "kubeclarity" {
  name       = "kubeclarity"
  chart      = "kubeclarity"
  version    = "2.23.0"
  namespace  = var.kubeclarity_namespace
  repository = "https://openclarity.github.io/kubeclarity"
  values = [
    templatefile("${path.module}/config/values.yaml", {
      hostname  = var.kubeclarity_hostname
      namespace = var.kubeclarity_namespace
    })
  ]
}