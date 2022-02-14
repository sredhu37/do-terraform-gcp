variable "gcp_config" {
  type = object({
    sa_credentials_file_path = string
    project                  = string
    region                   = string
  })
}
