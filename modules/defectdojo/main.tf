locals {
  template_file = templatefile("${path.module}/defectdojo-template/values.yaml", {
      hostname           = var.defectdojo_hostname,
      storage_class_name = var.storage_class_name,
      ingress_class_name = var.ingress_class_name
    })
  template_file_map = yamldecode(local.template_file)
}

resource "kubernetes_namespace" "defectdojo" {
  metadata {
    name = "defectdojo"
  }
}

resource "helm_release" "defectdojo" {
  depends_on = [kubernetes_namespace.defectdojo]
  name       = "defectdojo"
  namespace  = "defectdojo"
  chart      = "${path.module}/defectdojo-template/"
  timeout    = 600
  values = [yamlencode(merge(local.template_file_map, var.helm_config))]
}

data "kubernetes_secret" "defectdojo" {
  depends_on = [helm_release.defectdojo]
  metadata {
    name      = "defectdojo"
    namespace = "defectdojo"
  }
}