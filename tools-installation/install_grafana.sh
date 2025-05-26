#!/bin/bash
echo "Installing Grafana..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace grafana
helm install grafana grafana/grafana --namespace grafana
echo "Grafana installed in the grafana namespace"
