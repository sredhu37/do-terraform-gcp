module "global_vpc" {
  source = "./modules/networking"

  gcp_project                 = var.gcp_config.project
  vpc_name                    = local.network.vpc_name
  vpc_auto_create_subnetworks = local.network.vpc_auto_create_subnetworks
  vpc_routing_mode            = local.network.vpc_routing_mode
  private_subnet              = local.network.private_subnet
  public_subnet               = local.network.public_subnet
}

resource "google_compute_router" "cloud_router" {
  name    = "${module.global_vpc.private_subnet_name}-router"
  region  = module.global_vpc.private_subnet_region
  project = module.global_vpc.private_subnet_project
  network = module.global_vpc.global_vpc_name

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${module.global_vpc.private_subnet_name}-nat"
  region                             = google_compute_router.cloud_router.region
  project                            = module.global_vpc.private_subnet_project
  router                             = google_compute_router.cloud_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = module.global_vpc.private_subnet_name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "firewall_rule" {
  count = length(var.firewall_rules)

  name    = var.firewall_rules[count.index].name
  network = module.global_vpc.global_vpc_name

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
