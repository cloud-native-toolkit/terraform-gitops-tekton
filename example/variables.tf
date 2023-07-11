
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

variable "resource_group_name" {
}

variable "name_prefix" {
  default = ""
}

variable "region" {
}
