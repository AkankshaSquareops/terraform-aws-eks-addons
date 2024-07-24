output "defectdojo" {
  description = "DefectDojo endpoint and credentials"
  value = {
    username = "admin",
    password = nonsensitive(data.kubernetes_secret.defectdojo.data["DD_ADMIN_PASSWORD"]),
    url      = var.defectdojo_hostname
  }
}