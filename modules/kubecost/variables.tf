variable "kubecost_hostname" {
  description = "Specify the hostname for the kubecsot. "
  default     = ""
  type        = string
}

variable "cluster_issuer" {
  description = "Specify the letsecrypt cluster-issuer for ingress tls. "
  default     = ""
  type        = string
}

variable "worker_iam_role_arn" {
  description = "Specify the IAM role Arn for the nodes"
  default     = ""
  type        = string
}

variable "eks_cluster_name" {
  description = "Fetch Cluster ID of the cluster"
  default     = ""
  type        = string
}

variable "ingress_class_name" {
  description = "Specify the Ingress Class Name"
  default = ""
  type = string
}

variable "kubernetes_version" {
  description = "Specify cluster Kubernetes Version"
  default = ""
  type = any
}

variable "kubecost_enabled" {
  description = "Enable or disable the deployment of an Kubecost for Kubernetes."
  type        = bool
  default     = false
}