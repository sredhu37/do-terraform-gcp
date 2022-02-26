terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]

  backend "gcs" {
    bucket = "tf-state-dev-sunny-tf-gcp-2"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.1.0"
    }
  }
}

provider "google" {
  credentials = file(var.gcp_config.sa_credentials_file_path)

  project = var.gcp_config.project
  region  = var.gcp_config.region
}

data "terraform_remote_state" "tf_remote_state" {
  backend = "gcs"
  config = {
    bucket = "tf-state-dev-sunny-tf-gcp-2"
    prefix = "terraform/state"
  }
}

locals {
  network = defaults(var.network, {
    vpc_auto_create_subnetworks = "false"
    vpc_routing_mode            = "GLOBAL"

    private_subnet = {
      private_ip_google_access = "true"
    }

    public_subnet = {
      private_ip_google_access = "true"
    }
  })

  bastion = defaults(var.bastion, {
    disk_size = 10
  })

  firewall_rules = defaults(var.firewall_rules, {
    direction = "INGRESS"
  })
}
