// Live

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

// This is needed b/c this can never
// change without destroying the deployment first
resource "random_id" "deployment_id" {
  byte_length = 8
}

module "pod_template" {
  source = "../kube_pod"

  namespace           = var.namespace
  service_account     = var.service_account
  priority_class_name = var.priority_class_name
  dns_policy          = var.dns_policy
  pod_annotations     = var.pod_annotations

  containers = var.containers

  config_map_mounts = var.config_map_mounts
  secret_mounts     = var.secret_mounts
  secrets           = var.secrets
  common_env        = var.common_env
  dynamic_secrets   = var.dynamic_secrets

  tmp_directories = var.tmp_directories
  mount_owner     = var.mount_owner

  workload_name                         = var.namespace
  match_labels                          = { id = random_id.deployment_id.hex }
  burstable_nodes_enabled               = var.burstable_nodes_enabled
  spot_nodes_enabled                    = var.spot_nodes_enabled
  instance_type_anti_affinity_preferred = var.instance_type_anti_affinity_preferred
  instance_type_anti_affinity_required  = var.instance_type_anti_affinity_required
  zone_anti_affinity_required           = var.zone_anti_affinity_required
  host_anti_affinity_required           = var.host_anti_affinity_required
  extra_tolerations                     = var.extra_tolerations
  controller_node_required              = var.controller_node_required
  prefer_spot_nodes_enabled             = var.prefer_spot_nodes_enabled
  prefer_burstable_nodes_enabled        = var.prefer_burstable_nodes_enabled

  # generate: common_vars.snippet.txt
  pf_stack_version = var.pf_stack_version
  pf_stack_commit  = var.pf_stack_commit
  environment      = var.environment
  region           = var.region
  pf_root_module   = var.pf_root_module
  pf_module        = var.pf_module
  is_local         = var.is_local
  extra_tags       = var.extra_tags
  # end-generate
}

resource "kubectl_manifest" "deployment" {
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      namespace = var.namespace
      name      = var.name
      labels    = module.pod_template.labels
      annotations = {
        "reloader.stakater.com/auto" = "true"
      }
    }
    spec = {
      replicas = var.min_replicas
      strategy = {
        type = var.deployment_update_type
      }
      selector = {
        matchLabels = module.pod_template.match_labels
      }
      template = module.pod_template.pod_template
    }
  })
  server_side_apply = true
  force_conflicts   = true
  wait_for_rollout  = var.wait_for_rollout
}

resource "kubernetes_manifest" "vpa_server" {
  count = var.vpa_enabled ? 1 : 0
  manifest = {
    apiVersion = "autoscaling.k8s.io/v1"
    kind       = "VerticalPodAutoscaler"
    metadata = {
      name      = var.name
      namespace = var.namespace
      labels    = module.pod_template.labels
    }
    spec = {
      targetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = var.name
      }
      updatePolicy = {
        updateMode = "Auto"
      }
      resourcePolicy = {
        containerPolicies = [for config in var.containers : {
          containerName = config.name
          minAllowed = {
            memory = "${config.minimum_memory}Mi"
            cpu    = "${config.minimum_cpu}m"
          }
        }]
      }
    }
  }
  depends_on = [kubectl_manifest.deployment]
}


# Todo: Need to enable a custom metrics query via prometheus
# for multi-dimensional autoscaling
#resource "kubernetes_horizontal_pod_autoscaler_v2" "autoscaler" {
#  metadata {
#    name = var.service_name
#    namespace = var.namespace
#    labels = module.kube_labels.kube_labels
#  }
#  spec {
#    scale_target_ref {
#      api_version = "apps/v1"
#      kind = "Deployment"
#      name = kubernetes_deployment.deployment.metadata[0].name
#    }
#    min_replicas = local.min_replicas
#    max_replicas = var.max_replicas
#    metric {
#      type = "Resource"
#      resource {
#        name = "memory"
#        target {
#          type = "Utilization"
#          average_utilization = 75
#        }
#      }
#    }
#    metric {
#      type = "Resource"
#      resource {
#        name = "cpu"
#        target {
#          type = "Utilization"
#          average_utilization = 75
#        }
#      }
#    }
#    behavior {
#      scale_down {
#        select_policy                = "Max"
#        stabilization_window_seconds = 300
#
#        policy {
#          period_seconds = 60
#          type           = "Pods"
#          value          = 1
#        }
#      }
#
#      scale_up {
#        select_policy                = "Max"
#        stabilization_window_seconds = 300
#
#        policy {
#          period_seconds = 60
#          type           = "Pods"
#          value          = 1
#        }
#      }
#    }
#  }
#}

resource "kubernetes_manifest" "pdb" {
  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "${var.name}-pdb"
      namespace = var.namespace
      labels    = module.pod_template.labels
    }
    spec = {
      selector = {
        matchLabels = module.pod_template.match_labels
      }
      maxUnavailable             = 1
      unhealthyPodEvictionPolicy = "AlwaysAllow"
    }
  }
}

