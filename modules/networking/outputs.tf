output "global_vpc_name" {
  value = google_compute_network.global_vpc.name
}

output "public_subnet_name" {
  value = google_compute_subnetwork.public_subnet.name
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private_subnet.name
}

output "private_subnet_region" {
  value = google_compute_subnetwork.private_subnet.region
}

output "private_subnet_project" {
  value = google_compute_subnetwork.private_subnet.project
}
