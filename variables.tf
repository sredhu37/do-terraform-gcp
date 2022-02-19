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

variable "instances" {
  type = list(object({
    name         = string
    machine_type = string
    disk_image   = optional(string)
    disk_size    = optional(number)
    region       = optional(string)
    zone         = string
    subnetwork   = string
    tags         = optional(list(string))
  }))

  default = []
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