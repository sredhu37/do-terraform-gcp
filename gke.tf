resource "google_container_cluster" "private_gke" {
  name                     = var.gke.name
  location                 = var.gke.location
  project                  = var.gke.project
  network                  = module.global_vpc.global_vpc_name
  subnetwork               = module.global_vpc.private_subnet_name
  cluster_ipv4_cidr        = var.gke.cluster_ipv4_cidr
  initial_node_count       = var.gke.initial_node_count
  remove_default_node_pool = var.gke.remove_default_node_pool
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "access-master-from-bastion"
      cidr_block   = "${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip}/32"
    }
  }

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