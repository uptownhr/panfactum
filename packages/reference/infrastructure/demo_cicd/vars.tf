variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "github_username" {
  description = "The username of the GitHub account used by the CI/CD system"
  type = string
}

variable "github_token" {
  description = "The API token of the GitHub account used by the CI/CD system"
  type = string
  sensitive= true
}

variable "webhook_domain" {
  description = "The domain to use for the EventSource webhook"
  type = string
}

variable "buildkit_bucket_name" {
  description = "The S3 bucket to use as the layer cache"
  type = string
}

variable "buildkit_bucket_region" {
  description = "The region of the S3 bucket to use as the layer cache"
  type = string
}

variable "authentik_token" {
  description = "An API token for setting up Authentik"
  type = string
  sensitive = true
}

variable "pull_through_cache_enabled" {
  description = "Whether to use the ECR pull through cache for the deployed images"
  type        = bool
  default     = false
}

# pf-generate: standard_vars
variable "environment" {
  description = "The name of the environment the infrastructure is being deployed into. #injected"
  type        = string
  default     = null
}

variable "pf_root_module" {
  description = "The name of the root Panfactum module in the module tree. #injected"
  type        = string
  default     = "image_builder_panfactum"
}

variable "pf_module" {
  description = "The name of the Panfactum module where the containing resources are directly defined. #injected"
  type        = string
  default     = "image_builder_panfactum"
}

variable "region" {
  description = "The region the infrastructure is being deployed into. #injected"
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "Extra tags or labels to add to the created resources. #injected"
  type        = map(string)
  default     = {}
}

variable "is_local" {
  description = "Whether this module is a part of a local development deployment #injected"
  type        = bool
  default     = false
}

variable "pf_stack_version" {
  description = "Which version of the Panfactum stack is being used (git ref) #injected"
  type        = string
  default     = "main"
}

variable "pf_stack_commit" {
  description = "The commit hash for the version of the Panfactum stack being used #injected"
  type        = string
  default     = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
# end-generate
