
module "dev_tools_namespace" {
  source = "github.com/cloud-native-toolkit/terraform-k8s-namespace.git"

  cluster_config_file_path = module.cluster.config_file_path
  name                     = var.namespace
}

resource null_resource write_namespace {
  provisioner "local-exec" {
    command = "echo -n '${module.dev_tools_namespace.name}' > .namespace"
  }
}
