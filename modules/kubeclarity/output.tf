output "kubeclarity" {
  description = "Kubeclarity endpoint and credentials"
  value = {
    username = "admin",
    password = nonsensitive(random_password.kube-clarity[0].result),
    url      = var.kubeclarity_hostname
  }
}