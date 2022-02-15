terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]

  backend "gcs" {
    bucket = "tf-state-dev-sunny-tf-gcp"
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
    bucket = "tf-state-dev-sunny-tf-gcp"
    prefix = "terraform/state"
  }
}

locals {
  networks = defaults(var.networks, {
    vpc_auto_create_subnetworks = "false"
    vpc_routing_mode            = "GLOBAL"

    subnets = {
      private_ip_google_access = "true"
    }
  })
}

module "global_vpc_1" {
  source = "./modules/networking"

  count = length(local.networks)

  gcp_project                 = var.gcp_config.project
  vpc_name                    = local.networks[count.index].vpc_name
  vpc_auto_create_subnetworks = local.networks[count.index].vpc_auto_create_subnetworks
  vpc_routing_mode            = local.networks[count.index].vpc_routing_mode
  subnets                     = local.networks[count.index].subnets
}
