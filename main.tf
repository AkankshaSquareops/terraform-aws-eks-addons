data "aws_region" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

## EBS CSI DRIVER
module "aws-ebs-csi-driver" {
  source                               = "./modules/aws-ebs-csi-driver"
  count                                = var.enable_amazon_eks_aws_ebs_csi_driver || var.enable_self_managed_aws_ebs_csi_driver ? 1 : 0
  enable_amazon_eks_aws_ebs_csi_driver = var.enable_amazon_eks_aws_ebs_csi_driver
  addon_config = merge(
    {
      kubernetes_version = local.eks_cluster_version
    },
    var.amazon_eks_aws_ebs_csi_driver_config,
  )
  addon_context                          = local.addon_context
  enable_self_managed_aws_ebs_csi_driver = var.enable_self_managed_aws_ebs_csi_driver
  helm_config = merge(
    {
      kubernetes_version = local.eks_cluster_version
    },
    var.self_managed_aws_ebs_csi_driver_helm_config,
  )
}

## EFS CSI DRIVER
module "aws-efs-csi-driver" {
  source            = "./modules/aws-efs-csi-driver"
  count             = var.efs_storage_class_enabled ? 1 : 0
  helm_config       = var.aws_efs_csi_driver_helm_config
  irsa_policies     = var.aws_efs_csi_driver_irsa_policies
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

## EFS FILESYSTEM WITH Storage class
module "aws-efs-filesystem-with-storage-class" {
  source      = "./modules/aws-efs-filesystem-with-storage-class"
  count       = var.efs_storage_class_enabled ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  environment = var.environment
  kms_key_arn = var.kms_key_arn
  subnets     = var.private_subnet_ids
}

## LOAD BALANCER CONTROLLER
module "aws-load-balancer-controller" {
  source = "./modules/aws-load-balancer-controller"
  count  = var.aws_load_balancer_controller_enabled ? 1 : 0
  helm_config = {
    version = var.aws_load_balancer_version
    values  = var.aws_load_balancer_controller_helm_config.values
  }
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
}

## NODE TERMINATION HANDLER
module "aws-node-termination-handler" {
  source = "./modules/aws-node-termination-handler"
  count  = var.aws_node_termination_handler_enabled ? 1 : 0
  helm_config = {
    version = var.node_termination_handler_version
    values  = var.aws_node_termination_handler_helm_config.values
  }
  irsa_policies           = var.aws_node_termination_handler_irsa_policies
  autoscaling_group_names = var.auto_scaling_group_names
  addon_context           = local.addon_context
  enable_service_monitor  = var.aws_node_termination_handler_helm_config.enable_service_monitor
}

## VPC-CNI
module "aws_vpc_cni" {
  source      = "./modules/aws-vpc-cni"
  count       = var.amazon_eks_vpc_cni_enabled ? 1 : 0
  enable_ipv6 = var.enable_ipv6
  addon_config = merge(
    {
      kubernetes_version      = local.eks_cluster_version
      additional_iam_policies = [var.kms_policy_arn]
    }
  )
  addon_context = local.addon_context
}

## CERT MANAGER
module "cert-manager" {
  source                            = "./modules/cert-manager"
  count                             = var.cert_manager_enabled ? 1 : 0
  helm_config                       = var.cert_manager_helm_config
  manage_via_gitops                 = var.argocd_manage_add_ons
  irsa_policies                     = var.cert_manager_irsa_policies
  addon_context                     = local.addon_context
  domain_names                      = var.cert_manager_domain_names
  install_letsencrypt_issuers       = var.cert_manager_install_letsencrypt_r53_issuers
  letsencrypt_email                 = var.cert_manager_letsencrypt_email
  kubernetes_svc_image_pull_secrets = var.cert_manager_kubernetes_svc_image_pull_secrets
}

## CERT MANAGER LETSENCRYPT
module "cert-manager-le-http-issuer" {
  source                         = "./modules/cert-manager-le-http-issuer"
  count                          = var.cert_manager_enabled ? 1 : 0
  depends_on                     = [module.cert-manager]
  cert_manager_letsencrypt_email = var.cert_manager_helm_config.cert_manager_letsencrypt_email
}

## CLUSTER AUTOSCALER
module "cluster-autoscaler" {
  source              = "./modules/cluster-autoscaler"
  count               = var.cluster_autoscaler_enabled ? 1 : 0
  eks_cluster_version = local.eks_cluster_version
  helm_config = {
    version = var.cluster_autoscaler_chart_version
    values  = var.cluster_autoscaler_helm_config
  }
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

## COREDNS HPA
module "coredns_hpa" {
  source      = "./modules/core-dns-hpa"
  count       = var.coredns_hpa_enabled ? 1 : 0
  helm_config = var.coredns_hpa_helm_config
}

## EXTERNAL SECRETS
module "external-secrets" {
  source                                = "./modules/external-secret"
  count                                 = var.external_secrets_enabled ? 1 : 0
  helm_config                           = var.external_secrets_helm_config
  manage_via_gitops                     = var.argocd_manage_add_ons
  addon_context                         = local.addon_context
  irsa_policies                         = var.external_secrets_irsa_policies
  external_secrets_ssm_parameter_arns   = var.external_secrets_ssm_parameter_arns
  external_secrets_secrets_manager_arns = var.external_secrets_secrets_manager_arns
}

## NGINX INGRESS
module "ingress-nginx" {
  source            = "./modules/ingress-nginx"
  count             = var.ingress_nginx_enabled ? 1 : 0
  depends_on        = [module.aws_vpc_cni, module.service-monitor-crd]
  helm_config       = var.ingress_nginx_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
  ip_family         = data.aws_eks_cluster.eks.kubernetes_network_config[0].ip_family

  # Template values for ingress-nginx and private-internal-nginx
  namespace              = var.ingress_nginx_config.namespace
  enable_private_nlb     = var.enable_private_nlb
  ingress_class_name     = var.enable_private_nlb ? "internal-${var.ingress_nginx_config.ingress_class_name}" : var.ingress_nginx_config.ingress_class_name
  enable_service_monitor = var.ingress_nginx_config.enable_service_monitor
}

## KARPENTER
module "karpenter" {
  source                    = "./modules/karpenter"
  count                     = var.karpenter_enabled ? 1 : 0
  worker_iam_role_name      = var.worker_iam_role_name
  eks_cluster_name          = var.eks_cluster_name
  helm_config               = var.karpenter_helm_config
  irsa_policies             = var.karpenter_irsa_policies
  node_iam_instance_profile = var.karpenter_node_iam_instance_profile
  manage_via_gitops         = var.argocd_manage_add_ons
  addon_context             = local.addon_context
  kms_key_arn               = var.karpenter_enabled ? var.kms_key_arn : ""
}

## Karpenter-provisioner
module "karpenter-provisioner" {
  source           = "./modules/karpenter-provisioner"
  count            = var.karpenter_provisioner_enabled ? 1 : 0
  depends_on       = [module.karpenter]
  ipv6_enabled     = var.ipv6_enabled
  karpenter_config = var.karpenter_provisioner_config
}

## KUBERNETES DASHBOARD
module "kubernetes-dashboard" {
  source                              = "./modules/kubernetes-dashboard"
  count                               = var.kubernetes_dashboard_enabled ? 1 : 0
  depends_on                          = [local.kubernetes_dashboard_dependencies]
  k8s_dashboard_hostname              = var.k8s_dashboard_hostname
  alb_acm_certificate_arn             = var.alb_acm_certificate_arn
  k8s_dashboard_ingress_load_balancer = var.k8s_dashboard_ingress_load_balancer
  ingress_class_name                  = var.ingress_nginx_config.ingress_class_name
}

## KEDA

module "keda" {
  source            = "./modules/keda"
  count             = var.keda_enabled ? 1 : 0
  helm_config       = var.keda_helm_config
  irsa_policies     = var.keda_irsa_policies
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

## METRIC SERVER
module "metrics-server" {
  source = "./modules/metrics-server"
  count  = var.metrics_server_enabled ? 1 : 0
  helm_config = {
    version = var.metrics_server_helm_version
    values  = var.metrics_server_helm_config
  }
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

## RELOADER
module "reloader" {
  source = "./modules/reloader"
  count  = var.reloader_enabled ? 1 : 0
  helm_config = {
    values                 = var.reloader_helm_config.values
    namespace              = "kube-system"
    create_namespace       = false
    enable_service_monitor = var.reloader_helm_config.enable_service_monitor
  }
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

## SINGLE AZ SC
module "single-az-sc" {
  for_each                             = { for sc in var.single_az_sc_config : sc.name => sc }
  source                               = "./modules/aws-ebs-storage-class"
  kms_key_id                           = var.kms_key_arn
  availability_zone                    = each.value.zone
  single_az_ebs_gp3_storage_class      = var.single_az_ebs_gp3_storage_class_enabled
  single_az_ebs_gp3_storage_class_name = each.value.name
}

## SERVICE MONITOR CRD
module "service-monitor-crd" {
  source = "./modules/service-monitor-crd"
  count  = var.service_monitor_crd_enabled ? 1 : 0
}

## VPA-CRDS
module "vpa-crds" {
  source      = "./modules/vpa-crds"
  count       = var.metrics_server_enabled ? 1 : 0
  helm-config = var.vpa_config.values[0]
}


module "velero" {
  source        = "./modules/velero"
  count         = var.velero_enabled ? 1 : 0
  name          = var.name
  region        = data.aws_region.current.name
  cluster_id    = var.eks_cluster_name
  environment   = var.environment
  velero_config = var.velero_config
}

module "istio" {
  source                         = "./modules/istio"
  count                          = var.istio_enabled ? 1 : 0
  depends_on                     = [module.cert-manager-le-http-issuer]
  ingress_gateway_enabled        = var.istio_config.ingress_gateway_enabled
  ingress_gateway_namespace      = var.istio_config.ingress_gateway_namespace
  envoy_access_logs_enabled      = var.istio_config.envoy_access_logs_enabled
  prometheus_monitoring_enabled  = var.istio_config.prometheus_monitoring_enabled
  cert_manager_letsencrypt_email = var.cert_manager_letsencrypt_email
  istio_values_yaml              = var.istio_config.istio_values_yaml
}

data "kubernetes_service" "istio-ingress" {
  count      = var.istio_enabled ? 1 : 0
  depends_on = [module.istio]
  metadata {
    name      = "istio-ingressgateway"
    namespace = var.istio_config.ingress_gateway_namespace
  }
}

##KUBECLARITY
module "kubeclarity" {
  source = "./modules/kubeclarity"
  count   = var.kubeclarity_enabled ? 1 : 0
  kubeclarity_enabled   = var.kubeclarity_enabled
}

#Kubecost
module "kubecost" {
  source              = "./modules/kubecost"
  count               = var.kubecost_enabled ? 1 : 0
  depends_on          = [ module.ingress-nginx ]
  cluster_issuer      = var.cluster_issuer
  ingress_class_name  = var.ingress_nginx_config.ingress_class_name
  eks_cluster_name    = var.eks_cluster_name
  worker_iam_role_arn = var.worker_iam_role_arn
  kubernetes_version  = data.aws_eks_cluster.eks.version
  kubecost_enabled    = var.kubecost_enabled
}

#Metrics-Server-VPA
module "metrics-server-vpa" {
  source     = "./modules/metrics-server-vpa"
  count      = var.metrics_server_enabled ? 1 : 0
  depends_on = [module.vpa-crds]
}

#defectdojo
resource "kubernetes_namespace" "defectdojo" {
  count = var.defectdojo_enabled ? 1 : 0
  metadata {
    name = "defectdojo"
  }
}

resource "helm_release" "defectdojo" {
  count      = var.defectdojo_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.defectdojo]
  name       = "defectdojo"
  namespace  = "defectdojo"
  chart      = "${path.module}/modules/defectdojo/"
  timeout    = 600
  values = [
    templatefile("${path.module}/modules/defectdojo/values.yaml", {
      hostname           = var.defectdojo_hostname,
      storage_class_name = var.storage_class_name
    })
  ]
}

data "kubernetes_secret" "defectdojo" {
  count      = var.defectdojo_enabled ? 1 : 0
  depends_on = [helm_release.defectdojo]
  metadata {
    name      = "defectdojo"
    namespace = "defectdojo"
  }
}

#falco
module "falco" {
  source = "./modules/falco"
  count      = var.falco_enabled ? 1 : 0
  slack_webhook = var.slack_webhook
}