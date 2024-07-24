variable "defectdojo_hostname" {
  description = "Specify the hostname for the kubecsot. "
  default     = ""
  type        = string
}

variable "storage_class_name" {
  description = "Specify the hostname for the kubecsot. "
  default     = "infra-service-sc"
  type        = string
}

variable "helm_config" {
  description = "Ingress NGINX Helm Configuration"
  type        = any
  default     = {}
}

variable "ingress_class_name" {
  description = "Enter the Ingress class name"
  type = string
  default = ""
}