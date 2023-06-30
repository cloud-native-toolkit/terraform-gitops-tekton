
variable "cluster_name" {
}

variable "namespace" {
  type        = string
  description = "Namespace for tools"
}

variable "git_repo" {
  default = "git-module-test"
}

variable "kubeseal_namespace" {
  default = "sealed-secrets"
}

variable "cp_entitlement_key" {
}

variable "resource_group_name" {
}

variable "name_prefix" {
}

variable "region" {
}
