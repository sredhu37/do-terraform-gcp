gcp_config = {
  sa_credentials_file_path = "./tf-gcp-sa-key.json"
  project                  = "sunny-tf-gcp"
  region                   = "europe-west3"
}

networks = [
  {
    vpc_name = "global-vpc-sunny"

    subnets = [
      {
        name          = "private-subnet-europe-west3"
        region        = "europe-west3"
        ip_cidr_range = "10.1.0.0/24"
      },
      {
        name          = "public-subnet-europe-west3"
        region        = "europe-west3"
        ip_cidr_range = "10.2.0.0/24"
      }
    ]
  }
]

instances = [
  {
    name         = "bastion1-europe-west3"
    machine_type = "g1-small"
    disk_image   = "debian-cloud/debian-9"
    disk_size    = 15
    region       = "europe-west3"
    zone         = "europe-west3-a"
    subnetwork   = "public-subnet-europe-west3"
    tags         = ["bastion"]
  }
]

firewall_rules = [
  {
    name               = "allow-ssh-ingress"
    network            = "global-vpc-sunny"
    allowed_protocol   = "tcp"
    allowed_ports      = ["22"]
    direction          = "INGRESS"
    target_tags        = ["bastion"]
    source_cidr_ranges = ["0.0.0.0/0"]
  }
]
