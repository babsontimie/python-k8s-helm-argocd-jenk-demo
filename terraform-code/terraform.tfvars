project_id="tf-build-dev"
region="europe-west2" # London
zone="europe-west2-a"
cluster_name="demo-gke"
network_name="demo-vpc"
subnet_name="demo-subnet"
artifact_repo_name="demo-images"
enable_jenkins=true 
# Git repo used by ArgoCD Application (your repo containing helm/ and argocd/)
git_repo_url=               # e.g. https://github.com/org/repo.git
git_target_revision="main" 
argocd_app_path="helm/python-k8s-demo"

# Hostname for ingress (optional)
app_ingress_host="demo.example.com"