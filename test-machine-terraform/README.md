# How to use this configuration

This is a terraform configuration to build multiple k3s cluster in Rancher.

## Why terraform

Rancher has the official supported [terraform provider](https://registry.terraform.io/providers/rancher/rancher2) which can create k3s cluster by configuration.  
In most cases, Ansible is great tool for managing large group of machines. But when it comes to manage resource lifecycle, that's the job for terraform.  
And the target use case of this repo is to create large group of k3s cluster in Rancher. Instead of creating k3s cluster directly, Rancher created k3s can manage the configuration of infrastructure components.

## Configuration details

To run this configuration, we need to input the variables for `main.tf`. The example of input is in `variables.tfvars.tmpl`.

```terraform
machine_config = {
  ssh_user     = "root"
  machines     = ["1.2.3.4", "2.3.4.5", "3.4.5.6"]
  ssh_key_path = "~/.ssh/id_rsa"
}

rancher_config = {
  api_url    = "https://localhost:9443"
  access_key = "xxx"
  secret_key = "xxx"
  insecure   = true
}
```

- The first one `machine_config` is the machine variables including the ssh user, ssh private key path and the machine ip list. To simpify the demo, only the ssh private key is supported.
- The second one `rancher_config` is the Rancher configuration. To simpify the demo, only necessary parameters is exported.

The demo main.tf configuration will read the `machine_config.machines` list to generate a k3s cluster with 1 master and 1 worker.  
By running following commands, you can run this configuration:

```bash
terraform init
terraform apply -auto-approve
```
