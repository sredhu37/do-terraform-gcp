gcp_config = {
  sa_credentials_file_path = "./tf-gcp-sa-key.json"
  project                  = "sunny-tf-gcp-2"
  region                   = "europe-west3"
}

network = {
  vpc_name = "global-vpc-sunny"

  private_subnet = {
    name          = "private-subnet-europe-west3"
    region        = "europe-west3"
    ip_cidr_range = "10.1.0.0/24"
  }

  public_subnet = {
    name          = "public-subnet-europe-west3"
    region        = "europe-west3"
    ip_cidr_range = "10.2.0.0/24"
  }
}

bastion = {
  name         = "bastion1-europe-west3"
  machine_type = "g1-small"
  disk_image   = "debian-cloud/debian-9"
  disk_size    = 15
  region       = "europe-west3"
  zone         = "europe-west3-a"
  tags         = ["bastion"]
}

firewall_rules = [
  {
    name               = "allow-public-ssh-ingress"
    allowed_protocol   = "tcp"
    allowed_ports      = ["22"]
    target_tags        = ["bastion"]
    source_cidr_ranges = ["0.0.0.0/0"]
  },
  {
    name             = "allow-ssh-gke-ingress"
    allowed_protocol = "tcp"
    allowed_ports    = ["22"]
    source_tags      = ["bastion"]
    target_tags      = ["gke-worker"]
  }
]

gke = {
  name     = "gke-private-cluster-europe-west3"
  location = "europe-west3-a" # For master; Can be a Region or a Zone
  project  = "sunny-tf-gcp-2"
  # A "multi-zonal" cluster is a zonal cluster with at least one additional zone defined;
  # in a multi-zonal cluster, the cluster master is only present in a single zone while nodes are present in each of the primary zone and the node locations.
  # In contrast, in a regional cluster, cluster master nodes are present in multiple zones in the region.
  # For that reason, regional clusters should be preferred.
  cluster_ipv4_cidr = "10.20.0.0/14" # IP range for Pods

  # master_authorized_networks_config_cidr_blocks = {
  #   cidr_block   = ""         # <IP of bastion machine>/32
  #   display_name = "bastion1-europe-west3-access"
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
    name               = "e2-small-europe-west3-1"
    project            = "sunny-tf-gcp-2"
    location           = "europe-west3-a" # region or zone of the cluster
    node_locations     = ["europe-west3-b"]
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
    name               = "e2-medium-europe-west3-2"
    project            = "sunny-tf-gcp-2"
    location           = "europe-west3-a" # region or zone of the cluster
    node_locations     = ["europe-west3-c"]
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
