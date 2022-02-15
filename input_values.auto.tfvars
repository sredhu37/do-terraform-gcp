gcp_config = {
  sa_credentials_file_path = "./tf-gcp-sa-key.json"
  project                  = "sunny-tf-gcp"
  region                   = "europe-west3"
}

networks = [
  {
    vpc_name = "global-vpc-1"

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
