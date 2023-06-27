locals {
  name                 = "tekton"
  yaml_dir             = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"

  package              = data.gitops_metadata_packages.packages[0]
  package_name         = local.package.package_name
  catalog_source_namespace = local.package.catalog_source_namespace
  catalog_source       = local.package.catalog_source
  default_channel      = local.package.default_channel
  created_by           = "tekton-${random_string.random.result}"

  openshift_cluster   = length(regexall("^openshift", local.package_name)) > 0
  cluster_type        = data.gitops_metadata_cluster.cluster.cluster_type
  console_host        = data.gitops_metadata_cluster.cluster.default_ingress_subdomain
  operator_namespace  = local.openshift_cluster ? "openshift-operators" : "operators"
  dashboard_namespace = local.openshift_cluster ? "openshift-pipelines" : "tekton-pipelines"

  values_content = {
    tekton-operator = {
      clusterType       = local.cluster_type
      olmNamespace      = local.catalog_source_namespace
      operatorNamespace = local.operator_namespace
      createdBy         = local.created_by
      app               = "tekton"
      ocpCatalog        = {
        source  = local.catalog_source
        name    = local.package_name
        channel = local.default_channel
      }
      operatorHub       = {
        source  = local.catalog_source
        name    = local.package_name
        channel = local.default_channel
      }
      tektonNamespace = local.dashboard_namespace
    }
  }

  layer = "services"
  type  = "operators"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
}

resource "random_string" "random" {
  length           = 16
  lower            = true
  numeric          = true
  upper            = false
  special          = false
}

data gitops_metadata_cluster cluster {
  server_name = var.server_name
  branch = local.application_branch
  credentials = var.git_credentials
  config = var.gitops_config
}

data gitops_metadata_packages packages {
  server_name = var.server_name
  branch = local.application_branch
  credentials = var.git_credentials
  config = var.gitops_config
  package_name_filter = ["openshift-pipelines-operator-rh", "tektoncd-operator"]
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${path.module}/chart/tekton' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml]

  name = local.name
  namespace = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
