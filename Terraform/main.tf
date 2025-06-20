terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "proyecto-en-terraform"
  region  = "us-central1"
  zone    = "us-central1-c" # Usando la misma zona para la VM y el provider para consistencia
}
## Configuración de Red: VPC y Subred

resource "google_compute_network" "mi_vpc" {
  name                    = "mi-vpc"
  auto_create_subnetworks = false # Deshabilitar la creación automática de subredes
}

resource "google_compute_subnetwork" "mi_subred" {
  name          = "mi-subred"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.mi_vpc.id
}


## Reglas de Firewall

# Regla de firewall para permitir HTTP, HTTPS y puertos específicos para tu aplicación
# La regla solo aplicará a instancias con el tag "app-server"
resource "google_compute_firewall" "allow_app_ports" {
  name    = "allow-app-ports"
  network = google_compute_network.mi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "3001", "3000", "9100", "9090", "5432"] # Ajusta estos puertos según tu aplicación
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app-server"] # El tag que se asignará a tu VM
}

# Regla de firewall para permitir conexiones SSH (puerto 22)
# La regla solo aplicará a instancias con el tag "app-server"
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.mi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app-server"] # El tag que se asignará a tu VM
}

## Configuración de la Instancia de VM

resource "google_compute_instance" "mi_vm" {
  name         = "vm-docker"
  machine_type = "e2-standard-2"
  zone         = "us-central1-c" # Asegurarse de que la zona de la VM coincida con la del provider

  boot_disk {
    initialize_params {
      # Usar la imagen LTS de Ubuntu 22.04 directamente desde el proyecto de Canonical
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20 # 20 GB es un buen tamaño para el OS y Docker
    }
  }

  network_interface {
    network    = google_compute_network.mi_vpc.id
    subnetwork = google_compute_subnetwork.mi_subred.id
    access_config {
      // Esta configuración asigna una IP pública a la VM
    }
  }

  # Asignar una cuenta de servicio a la VM
  # El scope "cloud-platform" otorga amplios permisos. Para producción, considera usar scopes más específicos.
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

  # Se aplica el tag "app-server" para que las reglas de firewall lo apliquen.
  tags = ["app-server"]

  # Se ha comentado la sección 'metadata.ssh-keys' porque GCP gestiona las claves SSH
  # automáticamente al conectarse desde la consola. Si necesitas claves específicas,
  # asegúrate de que el formato sea correcto y el usuario SSH coincida.
  # metadata = {
  #   ssh-keys = "gcp-user:ssh-rsa AAAAB3... tu_clave_publica"
  # }
}