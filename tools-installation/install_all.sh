#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
section() {
    echo -e "${YELLOW}"
    echo "---------------------------------------------------------------------"
    echo " $1"
    echo "---------------------------------------------------------------------"
    echo -e "${NC}"
}

# Function to handle errors
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Update system packages first
section "Updating System Packages"
sudo apt-get update -y || error_exit "Failed to update packages"
sudo apt-get upgrade -y || error_exit "Failed to upgrade packages"

# Install common dependencies
section "Installing Common Dependencies"
sudo apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    unzip \
    default-jre \
    || error_exit "Failed to install dependencies"

# 1. Install Terraform
section "Installing Terraform"
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null || error_exit "Failed to add HashiCorp GPG key"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list || error_exit "Failed to add HashiCorp repo"
sudo apt update && sudo apt install -y terraform || error_exit "Failed to install Terraform"
echo -e "${GREEN}Terraform installed: $(terraform --version)${NC}"

# 2. Install Docker
section "Installing Docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || error_exit "Failed to add Docker GPG key"
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repo"
sudo apt update && sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin || error_exit "Failed to install Docker"
sudo usermod -aG docker $USER || error_exit "Failed to add user to docker group"
echo -e "${GREEN}Docker installed: $(docker --version)${NC}"

# 3. Install SonarQube
section "Installing SonarQube"
sudo docker pull sonarqube:lts || error_exit "Failed to pull SonarQube image"
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts || error_exit "Failed to start SonarQube"
echo -e "${GREEN}SonarQube installed and running on port 9000${NC}"

# 4. Install OWASP ZAP
section "Installing OWASP ZAP"
ZAP_VERSION=2.12.0
wget -q https://github.com/zaproxy/zaproxy/releases/download/v$ZAP_VERSION/ZAP_$ZAP_VERSION\_Linux.tar.gz || error_exit "Failed to download OWASP ZAP"
tar -xzf ZAP_$ZAP_VERSION\_Linux.tar.gz || error_exit "Failed to extract OWASP ZAP"
sudo mv ZAP_$ZAP_VERSION /opt/zaproxy || error_exit "Failed to move ZAP to /opt"
sudo ln -sf /opt/zaproxy/zap.sh /usr/local/bin/zap || error_exit "Failed to create symlink"
rm ZAP_$ZAP_VERSION\_Linux.tar.gz
echo -e "${GREEN}OWASP ZAP installed: $(zap -version)${NC}"

# 5. Install Trivy
section "Installing Trivy"
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/trivy.gpg > /dev/null || error_exit "Failed to add Trivy GPG key"
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
    https://aquasecurity.github.io/trivy-repo/deb \
    $(lsb_release -sc) main" | \
    sudo tee -a /etc/apt/sources.list.d/trivy.list || error_exit "Failed to add Trivy repo"
sudo apt update && sudo apt install -y trivy || error_exit "Failed to install Trivy"
echo -e "${GREEN}Trivy installed: $(trivy --version)${NC}"

# 6. Install Helm
section "Installing Helm"
curl -fsSL https://baltocdn.com/helm/signing.asc | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/helm.gpg > /dev/null || error_exit "Failed to add Helm GPG key"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
    https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list || error_exit "Failed to add Helm repo"
sudo apt update && sudo apt install -y helm || error_exit "Failed to install Helm"
echo -e "${GREEN}Helm installed: $(helm version)${NC}"

# 7. Install Kubernetes Tools
section "Installing Kubernetes Tools"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg || error_exit "Failed to add Kubernetes GPG key"
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
    https://apt.kubernetes.io/ kubernetes-xenial main" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list || error_exit "Failed to add Kubernetes repo"
sudo apt update && sudo apt install -y kubelet kubeadm kubectl || error_exit "Failed to install Kubernetes tools"
sudo apt-mark hold kubelet kubeadm kubectl || error_exit "Failed to hold Kubernetes packages"
echo -e "${GREEN}Kubernetes tools installed:"
kubectl version --client --short
helm version --short
echo -e "${NC}"

# 8. Install ArgoCD
section "Installing ArgoCD"
kubectl create namespace argocd 2>/dev/null || echo "argocd namespace already exists"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || error_exit "Failed to install ArgoCD"
echo -e "${GREEN}ArgoCD installed in the argocd namespace${NC}"

# 9. Install Prometheus
section "Installing Prometheus"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || error_exit "Failed to add Prometheus repo"
helm repo update || error_exit "Failed to update Helm repos"
kubectl create namespace monitoring 2>/dev/null || echo "monitoring namespace already exists"
helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --set alertmanager.enabled=false \
    --set pushgateway.enabled=false || error_exit "Failed to install Prometheus"
echo -e "${GREEN}Prometheus installed in the monitoring namespace${NC}"

# 10. Install Grafana
section "Installing Grafana"
helm repo add grafana https://grafana.github.io/helm-charts || error_exit "Failed to add Grafana repo"
helm repo update || error_exit "Failed to update Helm repos"
kubectl create namespace grafana 2>/dev/null || echo "grafana namespace already exists"
helm upgrade --install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.enabled=true \
    --set persistence.size=1Gi \
    --set adminPassword=admin || error_exit "Failed to install Grafana"
echo -e "${GREEN}Grafana installed in the grafana namespace"
echo "🔑 Grafana admin password: admin"
echo "Access Grafana by running: kubectl port-forward svc/grafana -n grafana 3000:80"
echo -e "${NC}"

# Final completion message
echo -e "${GREEN}"
echo "---------------------------------------------------------------------"
echo " All tools installed successfully!"
echo "---------------------------------------------------------------------"
echo -e "${NC}"
