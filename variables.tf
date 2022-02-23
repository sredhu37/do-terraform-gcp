variable "gcp_config" {
  type = object({
    sa_credentials_file_path = string
    project                  = string
    region                   = string
  })
}

variable "networks" {
  type = list(object({
    vpc_name                    = string
    vpc_auto_create_subnetworks = optional(string)
    vpc_routing_mode            = optional(string)

    subnets = list(object({
      region                   = string
      name                     = string
      ip_cidr_range            = string
      private_ip_google_access = optional(string)
    }))
  }))

  default = []
}

variable "bastion" {
  type = object({
    name         = string
    machine_type = string
    disk_image   = optional(string)
    disk_size    = optional(number)
    region       = optional(string)
    zone         = string
    subnetwork   = string
    tags         = optional(list(string))
  })
}

variable "firewall_rules" {
  type = list(object({
    name               = string
    network            = string
    allowed_protocol   = string
    allowed_ports      = list(string)
    direction          = optional(string)
    source_cidr_ranges = optional(list(string))
    source_tags        = optional(list(string))
    target_tags        = optional(list(string))
  }))

  default = []
}

variable "gke" {
  type = object({
    name                     = string
    location                 = string
    project                  = string
    network                  = string
    subnetwork               = string
    cluster_ipv4_cidr        = string
    initial_node_count       = number
    remove_default_node_pool = bool
    private_cluster_config = object({
      enable_private_nodes         = bool
      master_ipv4_cidr_block       = string
      master_global_access_enabled = bool
      enable_private_endpoint      = bool
    })
  })
}

variable "node_pools" {
  type = list(object({
    name               = string
    project            = string
    location           = string
    node_locations     = list(string)
    initial_node_count = number
    autoscaling = object({
      min_node_count = number
      max_node_count = number
    })

    management = object({
      auto_repair  = bool
      auto_upgrade = bool
    })

    upgrade_settings = object({
      max_surge       = number
      max_unavailable = number
    })

    node_config = object({
      machine_type = string
      tags         = list(string)
    })
  }))
}
