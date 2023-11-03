terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 3.2.0"

    }
  }
}

variable "rancher_config" {
  type = object({
    api_url    = string
    access_key = string
    secret_key = string
    insecure   = bool
  })
}

variable "machine_config" {
  type = object({
    ssh_user     = string
    ssh_key_path = string
    machines     = list(string)
  })
}

provider "rancher2" {
  alias = "admin"

  api_url = var.rancher_config.api_url
  access_key = var.rancher_config.access_key
  secret_key = var.rancher_config.secret_key
  insecure = var.rancher_config.insecure
}

resource "rancher2_cluster_v2" "testk3s" {
  count    = ceil(length(var.machine_config.machines) / 2)
  provider = rancher2.admin

  name               = "testk3s-${count.index}"
  kubernetes_version = "v1.26.8+k3s1"
  rke_config {
    registries {
      mirrors {
        hostname  = "docker.io"
        endpoints = ["https://docker.nju.edu.cn"]
      }
    }
  }
}

resource "terraform_data" "k3s-master" {
  depends_on = [rancher2_cluster_v2.testk3s]
  count      = length(rancher2_cluster_v2.testk3s)
  connection {
    type        = "ssh"
    host        = var.machine_config.machines[count.index * 2]
    user        = var.machine_config.ssh_user
    private_key = file(var.machine_config.ssh_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster_v2.testk3s[count.index].cluster_registration_token[0].insecure_node_command} --etcd --controlplane --worker"
    ]
  }
}

resource "terraform_data" "k3s_worker" {
  depends_on = [terraform_data.k3s-master]
  count      = length(var.machine_config.machines) - length(terraform_data.k3s-master)
  connection {
    type        = "ssh"
    host        = var.machine_config.machines[count.index * 2 + 1]
    user        = var.machine_config.ssh_user
    private_key = file(var.machine_config.ssh_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster_v2.testk3s[count.index].cluster_registration_token[0].insecure_node_command} --worker"
    ]
  }
}
