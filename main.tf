terraform {
  backend "gcs" {
    bucket = "tf-state-dev-sunny-tf-gcp"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.1.0"
    }
  }
}

provider "google" {
  #  credentials = file(var.gcp_config.sa_credentials_file_path)

  project = var.gcp_config.project
  region  = var.gcp_config.region
}

data "terraform_remote_state" "tf_remote_state" {
  backend = "gcs"
  config = {
    bucket = "tf-state-dev-sunny-tf-gcp"
    prefix = "terraform/state"
  }
}
