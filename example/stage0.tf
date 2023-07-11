terraform {
  required_providers {
    gitops = {
      source = "cloud-native-toolkit/gitops"
    }
    clis = {
      source = "cloud-native-toolkit/clis"
      version = ">= 0.4.1"
    }
  }
}

data clis_check test_clis {
  clis = ["kubectl", "oc"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = data.clis_check.test_clis.bin_dir
}
