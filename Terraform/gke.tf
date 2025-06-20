resource "google_container_cluster" "mi_gke" {
  name     = "mi-cluster-gke"                # Nombre del clúster en GCP
  location = "us-central1-c"                  # Zona donde se desplegará el clúster (zonal)
  network    = google_compute_network.mi_vpc.id    # Referencia a la VPC existente
  subnetwork = google_compute_subnetwork.mi_subred.id # Referencia a la subred existente

  remove_default_node_pool = true              # Elimina el node pool por defecto
  initial_node_count = 1                       # Requerido por el API, pero no se usa realmente
}

resource "google_container_node_pool" "mi_gke_nodes" {
  name       = "mi-gke-nodes"                 # Nombre del node pool
  cluster    = google_container_cluster.mi_gke.name   # Asocia el node pool al clúster
  location   = google_container_cluster.mi_gke.location # Zona del node pool

  node_count = 1                               # Número de nodos en el pool

  node_config {
    machine_type = "e2-small"                  # Tipo de máquina (pequeña para ahorrar recursos)
    disk_type    = "pd-standard"               # Tipo de disco estándar
    disk_size_gb = 20                          # Tamaño del disco de cada nodo (20GB)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Permisos de acceso a APIs de Google Cloud
    ]
    tags = ["gke-node"]                       # Etiqueta de red para los nodos
  }
} 