terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]
}

locals {
  private_subnet = defaults(var.private_subnet, {
    private_ip_google_access = "true"
  })

  public_subnet = defaults(var.public_subnet, {
    private_ip_google_access = "true"
  })
}

resource "google_compute_network" "global_vpc" {
  name                    = var.vpc_name
  project                 = var.gcp_project
  auto_create_subnetworks = var.vpc_auto_create_subnetworks
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_subnetwork" "private_subnet" {
  project                  = var.gcp_project
  name                     = local.private_subnet.name
  ip_cidr_range            = local.private_subnet.ip_cidr_range
  region                   = local.private_subnet.region
  network                  = google_compute_network.global_vpc.id
  private_ip_google_access = local.private_subnet.private_ip_google_access

  depends_on = [google_compute_network.global_vpc]
}

resource "google_compute_subnetwork" "public_subnet" {
  project                  = var.gcp_project
  name                     = local.public_subnet.name
  ip_cidr_range            = local.public_subnet.ip_cidr_range
  region                   = local.public_subnet.region
  network                  = google_compute_network.global_vpc.id
  private_ip_google_access = local.public_subnet.private_ip_google_access

  depends_on = [google_compute_network.global_vpc]
}

# resource "google_compute_router" "cloud_router" {
#   name    = "${google_compute_subnetwork.public_subnet.name}-cloud-router"
#   network = google_compute_network.global_vpc.name
#   region = local.public_subnet.region
#   project = var.gcp_project
#   bgp {
#     asn               = 64514
#     advertise_mode    = "CUSTOM"
#     advertised_groups = ["ALL_SUBNETS"]
#     advertised_ip_ranges {
#       range = "1.2.3.4"
#     }
#     advertised_ip_ranges {
#       range = "6.7.0.0/16"
#     }
#   }
# }