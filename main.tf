locals {
  name                 = "tekton"
  yaml_dir             = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"

  package              = data.gitops_metadata_packages.packages.packages[0]
  package_name         = local.package.package_name
  catalog_source_namespace = local.package.catalog_source_namespace
  catalog_source       = local.package.catalog_source
  default_channel      = local.package.default_channel
  created_by           = "tekton-${random_string.random.result}"

  openshift_cluster   = length(regexall("^openshift", local.package_name)) > 0
  cluster_type        = data.gitops_metadata_cluster.cluster.cluster_type
  console_host        = data.gitops_metadata_cluster.cluster.default_ingress_subdomain
  operator_namespace  = data.gitops_metadata_cluster.cluster.operator_namespace
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
    resource-owner-job = {
      owner = {
        group = "operators.coreos.com"
        kind = "Subscription"
        name = local.package_name
      }
      target = {
        group = "operators.coreos.com"
        kind = "ClusterServiceVersion"
      }
    }
  }

  layer = "services"
  type  = "operators"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]

  git_credentials = yamlencode(var.git_credentials)
  gitops_config = yamlencode(var.gitops_config)
}

resource "random_string" "random" {
  length           = 16
  lower            = true
  numeric          = true
  upper            = false
  special          = false
}

resource null_resource sync {
  provisioner "local-exec" {
    command = "echo 'Sync: ${var.sync}'"
  }
}

data gitops_metadata_cluster cluster {
  depends_on = [null_resource.sync]

  server_name = var.server_name
  branch = local.application_branch
  credentials = local.git_credentials
  config = local.gitops_config
}

data gitops_metadata_packages packages {
  depends_on = [null_resource.sync]

  server_name = var.server_name
  branch = local.application_branch
  credentials = local.git_credentials
  config = local.gitops_config
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
  namespace = local.operator_namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = local.gitops_config
  credentials = local.git_credentials
}
