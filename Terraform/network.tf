resource "google_compute_network" "mi_vpc" {
  name                    = "mi-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mi_subred" {
  name          = "mi-subred"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.mi_vpc.id
}

resource "google_compute_firewall" "allow_app_ports" {
  name    = "allow-app-ports"
  network = google_compute_network.mi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "3001", "3000", "9100", "9090", "5432"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.mi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app-server"]
} 