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

  instances = defaults(var.instances, {
    disk_size = 10
  })

  firewall_rules = defaults(var.firewall_rules, {
    direction = "INGRESS"
  })
}

module "global_vpc" {
  source = "./modules/networking"

  count = length(local.networks)

  gcp_project                 = var.gcp_config.project
  vpc_name                    = local.networks[count.index].vpc_name
  vpc_auto_create_subnetworks = local.networks[count.index].vpc_auto_create_subnetworks
  vpc_routing_mode            = local.networks[count.index].vpc_routing_mode
  subnets                     = local.networks[count.index].subnets
}

resource "google_compute_instance" "instance" {
  count = length(var.instances)

  name         = var.instances[count.index].name
  machine_type = var.instances[count.index].machine_type
  boot_disk {
    initialize_params {
      image = var.instances[count.index].disk_image != "" ? var.instances[count.index].disk_image : data.google_compute_image.debian10_image.self_link
      size  = local.instances[count.index].disk_size
    }
  }

  zone = var.instances[count.index].zone

  network_interface {
    subnetwork = var.instances[count.index].subnetwork

    # IPs via which this instance can be accessed via the Internet. Omit to ensure that the instance is not accessible from the Internet.
    access_config {
      nat_ip = google_compute_address.static_ip_address[count.index].address
    }
  }

  tags = var.instances[count.index].tags

  depends_on = [module.global_vpc]
}

resource "google_compute_address" "static_ip_address" {
  count = length(var.instances)

  name         = "${var.instances[count.index].name}-static-ip"
  network_tier = "PREMIUM"
  region       = var.instances[count.index].region != "" ? var.instances[count.index].region : var.gcp_config.region
}

resource "google_compute_firewall" "firewall_rule" {
  count = length(var.firewall_rules)

  name    = var.firewall_rules[count.index].name
  network = var.firewall_rules[count.index].network
  allow {
    protocol = var.firewall_rules[count.index].allowed_protocol
    ports    = var.firewall_rules[count.index].allowed_ports
  }

  direction     = local.firewall_rules[count.index].direction
  source_ranges = var.firewall_rules[count.index].source_cidr_ranges
  source_tags   = var.firewall_rules[count.index].source_tags
  target_tags   = var.firewall_rules[count.index].target_tags

  depends_on = [module.global_vpc]
}

data "google_compute_image" "debian10_image" {
  family  = "debian-10"
  project = "debian-cloud"
}
