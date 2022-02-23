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

  bastion = defaults(var.bastion, {
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

resource "google_compute_instance" "bastion" {
  name         = var.bastion.name
  machine_type = var.bastion.machine_type
  boot_disk {
    initialize_params {
      image = var.bastion.disk_image != "" ? var.bastion.disk_image : data.google_compute_image.debian10_image.self_link
      size  = local.bastion.disk_size
    }
  }

  zone = var.bastion.zone

  network_interface {
    subnetwork = var.bastion.subnetwork

    # IPs via which this instance can be accessed via the Internet. Omit to ensure that the instance is not accessible from the Internet.
    access_config {
      nat_ip = google_compute_address.bastion_static_ip_address.address
    }
  }

  tags = var.bastion.tags

  depends_on = [module.global_vpc]
}

resource "google_compute_address" "bastion_static_ip_address" {
  name         = "${var.bastion.name}-static-ip"
  network_tier = "PREMIUM"
  region       = var.bastion.region != "" ? var.bastion.region : var.gcp_config.region
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

resource "google_container_cluster" "private_gke" {
  name                     = var.gke.name
  location                 = var.gke.location
  project                  = var.gke.project
  network                  = var.gke.network
  subnetwork               = var.gke.subnetwork
  cluster_ipv4_cidr        = var.gke.cluster_ipv4_cidr
  initial_node_count       = var.gke.initial_node_count
  remove_default_node_pool = var.gke.remove_default_node_pool
  # master_authorized_networks_config = google_compute_instance.bastion.ip

  private_cluster_config {
    enable_private_nodes    = var.gke.private_cluster_config.enable_private_nodes
    master_ipv4_cidr_block  = var.gke.private_cluster_config.master_ipv4_cidr_block
    enable_private_endpoint = var.gke.private_cluster_config.enable_private_endpoint
    master_global_access_config {
      enabled = var.gke.private_cluster_config.master_global_access_enabled
    }
  }
}

resource "google_container_node_pool" "node_pool" {
  count = length(var.node_pools)

  name               = var.node_pools[count.index].name
  project            = var.node_pools[count.index].project
  location           = var.node_pools[count.index].location
  cluster            = google_container_cluster.private_gke.name
  node_locations     = var.node_pools[count.index].node_locations
  initial_node_count = var.node_pools[count.index].initial_node_count

  autoscaling {
    min_node_count = var.node_pools[count.index].autoscaling.min_node_count
    max_node_count = var.node_pools[count.index].autoscaling.max_node_count
  }

  management {
    auto_repair  = var.node_pools[count.index].management.auto_repair
    auto_upgrade = var.node_pools[count.index].management.auto_upgrade
  }

  upgrade_settings {
    max_surge       = var.node_pools[count.index].upgrade_settings.max_surge
    max_unavailable = var.node_pools[count.index].upgrade_settings.max_unavailable
  }

  node_config {
    machine_type = var.node_pools[count.index].node_config.machine_type
    tags         = var.node_pools[count.index].node_config.tags
  }
}
