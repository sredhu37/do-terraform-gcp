resource "google_compute_address" "sunny-jenkins-ingress-static-ip" {
  name        = "sunny-jenkins-ingress-static-ip"
  description = "External static ip for gke ingress sunny-jenkins deployment"
  region      = var.gcp_config.region
  project     = var.gcp_config.project
}

resource "google_compute_address" "argocd-ingress-static-ip" {
  name        = "argocd-ingress-static-ip"
  description = "External static ip for gke ingress argocd deployment"
  region      = var.gcp_config.region
  project     = var.gcp_config.project
}

resource "google_compute_address" "sunny-resume-ingress-static-ip" {
  name        = "sunny-resume-ingress-static-ip"
  description = "External static ip for gke ingress sunny-resume deployment"
  region      = var.gcp_config.region
  project     = var.gcp_config.project
}
