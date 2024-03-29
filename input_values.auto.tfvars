gcp_config = {
  sa_credentials_file_path = "./tf-gcp-sa-key.json"
  project                  = "sunny-tf-gcp-5"
  region                   = "europe-west4"
}

network = {
  vpc_name                    = "global-vpc-sunny"
  vpc_auto_create_subnetworks = "false"
  vpc_routing_mode            = "GLOBAL"

  private_subnet = {
    name                     = "private-subnet-europe-west4"
    region                   = "europe-west4"
    ip_cidr_range            = "10.1.0.0/24"
    private_ip_google_access = "true"
  }

  public_subnet = {
    name                     = "public-subnet-europe-west4"
    region                   = "europe-west4"
    ip_cidr_range            = "10.2.0.0/24"
    private_ip_google_access = "true"
  }
}

bastion = {
  name         = "bastion1-europe-west4"
  machine_type = "g1-small"
  disk_image   = "debian-cloud/debian-10"
  disk_size    = 15
  region       = "europe-west4"
  zone         = "europe-west4-a"
  tags         = ["bastion"]
}

firewall_rules = [
  {
    name               = "allow-public-ssh-ingress"
    allowed_protocol   = "tcp"
    allowed_ports      = ["22"]
    target_tags        = ["bastion"]
    source_cidr_ranges = ["0.0.0.0/0"]
    direction          = "INGRESS"
  },
  {
    name             = "allow-ssh-gke-ingress"
    allowed_protocol = "tcp"
    allowed_ports    = ["22"]
    source_tags      = ["bastion"]
    target_tags      = ["gke-worker"]
    direction        = "INGRESS"
  },

  {
    name               = "allow-gke-master-to-nodes-kubeseal"
    allowed_protocol   = "tcp"
    allowed_ports      = ["8080"]
    source_cidr_ranges = ["10.11.0.0/28"]
    target_tags        = ["gke-worker"]
    direction          = "INGRESS"
  }
]

gke = {
  name     = "gke-private-cluster-europe-west4"
  location = "europe-west4-a" # For master; Can be a Region or a Zone
  project  = "sunny-tf-gcp-5"
  # A "multi-zonal" cluster is a zonal cluster with at least one additional zone defined;
  # in a multi-zonal cluster, the cluster master is only present in a single zone while nodes are present in each of the primary zone and the node locations.
  # In contrast, in a regional cluster, cluster master nodes are present in multiple zones in the region.
  # For that reason, regional clusters should be preferred.
  cluster_ipv4_cidr = "10.20.0.0/14" # IP range for Pods

  # master_authorized_networks_config_cidr_blocks = {
  #   cidr_block   = ""         # <IP of bastion machine>/32
  #   display_name = "bastion1-europe-west4-access"
  # }

  initial_node_count       = 1
  remove_default_node_pool = true
  private_cluster_config = {
    enable_private_nodes         = true
    master_ipv4_cidr_block       = "10.11.0.0/28" # CIDR for master nodes IPs
    master_global_access_enabled = true
    enable_private_endpoint      = false
  }
}

# We will be using separately managed node pools
node_pools = [
  {
    name               = "e2-small-europe-west4-1"
    project            = "sunny-tf-gcp-5"
    location           = "europe-west4-a" # region or zone of the cluster
    node_locations     = ["europe-west4-b"]
    initial_node_count = 1
    autoscaling = {
      min_node_count = 1
      max_node_count = 5
    }
    management = {
      auto_repair  = true
      auto_upgrade = true
    }
    upgrade_settings = {
      max_surge       = 2
      max_unavailable = 1
    }
    node_config = {
      machine_type = "e2-small"
      tags         = ["gke-worker"]
    }
  },
  {
    name               = "e2-medium-europe-west4-2"
    project            = "sunny-tf-gcp-5"
    location           = "europe-west4-a" # region or zone of the cluster
    node_locations     = ["europe-west4-c"]
    initial_node_count = 1
    autoscaling = {
      min_node_count = 1
      max_node_count = 5
    }
    management = {
      auto_repair  = true
      auto_upgrade = true
    }
    upgrade_settings = {
      max_surge       = 2
      max_unavailable = 1
    }
    node_config = {
      machine_type = "e2-medium"
      tags         = ["gke-worker"]
    }
  }
]
