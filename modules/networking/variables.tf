variable "gcp_project" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_auto_create_subnetworks" {
  type    = string
  default = "false"
}

variable "vpc_routing_mode" {
  type    = string
  default = "GLOBAL"
}

variable "private_subnet" {
  type = object({
    region                   = string
    name                     = string
    ip_cidr_range            = string
    private_ip_google_access = string
  })
}

variable "public_subnet" {
  type = object({
    region                   = string
    name                     = string
    ip_cidr_range            = string
    private_ip_google_access = string
  })
}
