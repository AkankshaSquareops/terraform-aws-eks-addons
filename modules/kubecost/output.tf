output "kubecost" {
  description = "Kubecost endpoint and credentials"
  value = {
    username = "admin",
    password = nonsensitive(random_password.kubecost[0].result),
    url      = var.kubecost_hostname
  } 
}