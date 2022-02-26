resource "google_compute_address" "bastion_static_ip_address" {
  name         = "${var.bastion.name}-static-ip"
  network_tier = "PREMIUM"
  region       = var.bastion.region != "" ? var.bastion.region : var.gcp_config.region
  # network      = module.global_vpc.global_vpc_name
  # subnetwork   = module.global_vpc.public_subnet_name
}

resource "google_compute_instance" "bastion" {
  name         = var.bastion.name
  machine_type = var.bastion.machine_type
  boot_disk {
    initialize_params {
      image = var.bastion.disk_image != "" ? var.bastion.disk_image : data.google_compute_image.debian10_image.self_link
      size  = local.bastion.disk_size
    }
  }

  zone = var.bastion.zone

  network_interface {
    subnetwork = module.global_vpc.public_subnet_name

    # IPs via which this instance can be accessed via the Internet. Omit to ensure that the instance is not accessible from the Internet.
    access_config {
      nat_ip = google_compute_address.bastion_static_ip_address.address
    }
  }

  tags = var.bastion.tags

  depends_on = [module.global_vpc]
}
