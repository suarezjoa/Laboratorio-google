resource "google_compute_instance" "mi_vm" {
  name         = "vm-docker"
  machine_type = "e2-standard-2"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.mi_vpc.id
    subnetwork = google_compute_subnetwork.mi_subred.id
    access_config {}
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    "user-data" = <<EOT
#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker.io
  - git
runcmd:
  - curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  - chmod +x /usr/local/bin/docker-compose
  - ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
  - systemctl start docker
  - systemctl enable docker
  - git clone https://github.com/roxsross/roxs-devops-stack
  - cd roxs-devops-stack
  - sudo docker network create roxs-devops-network
  - sudo docker network create roxs-monitoring-network
  - sudo docker-compose -f docker-compose.yml up -d
  - sudo docker-compose -f docker-compose.monitoring.yml up -d
EOT
  }

  tags = ["app-server"]
} 