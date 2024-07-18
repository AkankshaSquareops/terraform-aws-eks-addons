variable "kubeclarity_hostname" {
  description = "Specify the hostname for the Kubeclarity. "
  default     = ""
  type        = string
}

variable "kubeclarity_namespace" {
  description = "Name of the Kubernetes namespace where the kubeclarity deployment will be deployed."
  default     = "kubeclarity"
  type        = string
}

variable "kubeclarity_enabled" {
  description = "Enable or disable the deployment of an kubeclarity for Kubernetes."
  default     = false
  type        = bool
}