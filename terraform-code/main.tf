provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "default" {}

# ---------------------------
# Networking (simple VPC)
# ---------------------------
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

# ---------------------------
# Artifact Registry (Docker)
# ---------------------------
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.artifact_repo_name
  description   = "Docker images"
  format        = "DOCKER"
}

# ---------------------------
# GKE Cluster (Workload Identity enabled)
# ---------------------------
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-4"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      env = "demo"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ---------------------------
# Kubernetes + Helm providers
# ---------------------------
provider "kubernetes" {
  host  = "https://${google_container_cluster.gke.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.gke.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.gke.master_auth[0].cluster_ca_certificate
    )
  }
}

# ---------------------------
# Install Argo CD via Helm
# ---------------------------
resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.12" # pin a known-good version

  # Basic sane defaults; expand as needed
  values = [yamlencode({
    server = {
      service = { type = "ClusterIP" }
    }
  })]
}

# ---------------------------
# App namespace
# ---------------------------
resource "kubernetes_namespace" "demo" {
  metadata { name = "demo" }
}

# ---------------------------
# Create Argo CD Application (points to your Helm chart in Git)
# ---------------------------
resource "kubernetes_manifest" "argocd_app" {
  depends_on = [helm_release.argocd, kubernetes_namespace.demo]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "python-k8s-demo"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_target_revision
        path           = var.argocd_app_path
        helm = {
          valueFiles = ["values.yaml"]
          parameters = [
            # Set ingress host from Terraform (optional)
            { name = "ingress.hosts[0].host", value = var.app_ingress_host }
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "demo"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}

# ---------------------------
# OPTIONAL: Install Jenkins via Helm
# ---------------------------
resource "kubernetes_namespace" "jenkins" {
  count = var.enable_jenkins ? 1 : 0
  metadata { name = "jenkins" }
}

resource "helm_release" "jenkins" {
  count      = var.enable_jenkins ? 1 : 0
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins[0].metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.6.5"

  # You’ll provide values file separately (jenkins/values-jenkins.yaml)
  values = [file("${path.module}/../jenkins/values-jenkins.yaml")]

  depends_on = [google_container_node_pool.primary]
}
