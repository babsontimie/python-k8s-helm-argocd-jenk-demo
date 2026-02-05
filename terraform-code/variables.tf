variable "project_id" {}
variable "region"     {"europe-west2" } # London
variable "zone"       { "europe-west2-a" }

variable "cluster_name" {"demo-gke" }
variable "network_name" {"demo-vpc" }
variable "subnet_name"  {"demo-subnet" }

variable "artifact_repo_name" {"demo-images" }

variable "enable_jenkins" { 
    type = bool 
    default = true 
    }

# Git repo used by ArgoCD Application (your repo containing helm/ and argocd/)
variable "git_repo_url" {}               # e.g. https://github.com/org/repo.git
variable "git_target_revision" {"main" }
variable "argocd_app_path" {"helm/python-k8s-demo"}

# Hostname for ingress (optional)
variable "app_ingress_host" {"demo.example.com"}
