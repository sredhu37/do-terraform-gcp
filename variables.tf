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
