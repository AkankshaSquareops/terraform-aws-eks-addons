output "environment" {
  description = "Environment Name for the EKS cluster"
  value       = var.environment
}

output "ebs_encryption_enable" {
  description = "Whether Amazon Elastic Block Store (EBS) encryption is enabled or not."
  value       = "Encrypted by default"
}

output "efs_id" {
  value       = var.efs_storage_class_enabled ? module.aws-efs-filesystem-with-storage-class.*.id : null
  description = "ID of the Amazon Elastic File System (EFS) that has been created for the EKS cluster."
}

output "kubeclarity" {
  description = "Kubeclarity endpoint and credentials"
  value       = module.kubeclarity[0].kubeclarity
}

output "kubecost" {
  value       = module.kubecost[0].kubecost
  description = "Kubecost endpoint and credentials"
}

output "istio_ingressgateway_dns_hostname" {
  description = "DNS hostname of the Istio Ingress Gateway."
  value       = var.istio_enabled ? try(data.kubernetes_service.istio-ingress[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
}

output "defectdojo" {
  description = "DefectDojo endpoint and credentials"
  value = var.defectdojo_enabled ? {
    username = "admin",
    password = nonsensitive(data.kubernetes_secret.defectdojo[0].data["DD_ADMIN_PASSWORD"]),
    url      = var.defectdojo_hostname
  } : null
}

output "k8s_dashboard_admin_token" {
  description = "Kubernetes-Dashboard Admin Token"
  value       = var.kubernetes_dashboard_enabled ? module.kubernetes-dashboard[0].k8s-dashboard-admin-token : ""
}

output "k8s_dashboard_read_only_token" {
  description = "Kubernetes-Dashboard Read Only Token"
  value       = var.kubernetes_dashboard_enabled ? module.kubernetes-dashboard[0].k8s-dashboard-read-only-token : ""
}
