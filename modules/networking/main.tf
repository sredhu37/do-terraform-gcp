terraform {
  required_version = ">= 1.0.0"
  experiments = [module_variable_optional_attrs]
}

locals {
  subnets = defaults(var.subnets, {
    private_ip_google_access = "true"
  })
}

resource "google_compute_network" "global_vpc" {
  name                    = var.vpc_name
  project                 = var.gcp_project
  auto_create_subnetworks = var.vpc_auto_create_subnetworks
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_subnetwork" "subnet" {
  count = length(local.subnets)

  project = var.gcp_project
  name = local.subnets[count.index].name
  ip_cidr_range = local.subnets[count.index].ip_cidr_range
  region = local.subnets[count.index].region
  network = google_compute_network.global_vpc.id
  private_ip_google_access = local.subnets[count.index].private_ip_google_access
}
