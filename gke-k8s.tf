resource "google_container_cluster" "cluster-1" {
  name    = "cluster-1"
  zone    = "us-central1-a"
  network = "projects/${var.google_project}/global/networks/default"

  lifecycle {
    ignore_changes = ["node_pool","ip_allocation_policy","id"]
  }

  node_pool {
    name = "pre-2cpu-8mem"
  }
  node_pool {
    name = "pre-1cpu-4mem"
  }
}
resource "google_container_node_pool" "pre-2cpu-8mem" {
  name       = "pre-2cpu-8mem"
  zone       = "us-central1-a"
  cluster    = "${google_container_cluster.cluster-1.name}"
  node_count = 0

  lifecycle {
    ignore_changes = ["id"]
  }
  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"
  }
}
resource "google_container_node_pool" "pre-1cpu-4mem" {
  name       = "pre-1cpu-4mem"
  zone       = "us-central1-a"
  cluster    = "${google_container_cluster.cluster-1.name}"
  node_count = 0

  lifecycle {
    ignore_changes = ["id"]
  }
  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
  }
}
