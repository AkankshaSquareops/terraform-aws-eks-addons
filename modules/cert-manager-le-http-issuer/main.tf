resource "helm_release" "cert-manager-le-http-issuer" {
  name    = "cert-manager-le-http-issuer"
  chart   = "${path.module}/config/"
  version = "0.1.0"
  values = [templatefile("${path.module}/config/values.yaml", {
    ingress_class_name = var.ingress_class_name
  })]
  set {
    name  = "email"
    value = var.cert_manager_letsencrypt_email
    type  = "string"
  }
}
