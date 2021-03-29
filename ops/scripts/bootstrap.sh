#!/usr/bin/env bash

CLUSTER_NAME=$1
KUBECTL_VERSION=1.20.0
K3D_VERSION=v4.3.0
SKAFFOLD_VERSION=1.20.0
K9S_VERSION=v0.24.3
LOCALSTACK_VERSION=0.12.7
TRAEFIK_VERSION=2.4.7
COREDNS_VERSION=1.8.0
KUBESTATE_METRICS_VERSION=v1.9.8
RANCHER_METRICS_SERVER=v0.3.6
RANCHER_KLIPPER_VERSION=v0.1.2
PROMETHEUS_ALERT_MANAGER_VERSION=v0.21.0
CONFIGMAP_RELOAD_VERSION=configmap-reload:v0.5.0
NODE_EXPORTER_VERSION=v1.0.1
PROMETHEUS_VERSION=v2.24.0
HELM_VERSION=v3.5.3

K9S_BINARY="k9s"
K3D_BINARY="k3d"
SKAFFOLD_BINARY="skaffold"
HELM_BINARY="helm"

K9S_FILE="k9s_Linux_x86_64.tar.gz"
k3D_FILE="k3d-linux-amd64"
SKAFFOLD_FILE="skaffold-linux-amd64"
KUBECTL_ARCH="linux"


# function to download basic binaries

function bootstrap() {
  os=$(echo $1 | tr '[A-Z]' '[a-z]')
  echo $os
  if [[ "$1" == "Darwin" ]]; then
    export K9S_FILE="k9s_Darwin_x86_64.tar.gz"
    export k3D_FILE="k3d-darwin-amd64"
    export SKAFFOLD_FILE="skaffold-darwin-amd64"
    export KUBECTL_ARCH="darwin"
  fi

  if [ ! -x "$(command -v "kubectl")" ]; then
    curl -LO https://dl.k8s.io/release/v1.20.0/bin/$KUBECTL_ARCH/amd64/kubectl -O /tmp/kubectl
      sudo chmod +x /tmp/kubectl
      sudo mv /tmp/kubectl /usr/local/bin
  fi

  if [ ! -x "$(command -v "$K3D_BINARY")" ]; then
    wget https://github.com/rancher/k3d/releases/download/${K3D_VERSION}/$k3D_FILE -O /tmp/k3d
    sudo chmod +x /tmp/k3d
    sudo mv /tmp/k3d /usr/local/bin
  fi

  if [ ! -x "$(command -v "$SKAFFOLD_BINARY")" ]; then
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/$SKAFFOLD_FILE -O /tmp/skaffold
    sudo chmod +x /tmp/skaffold
    sudo mv /tmp/skaffold /usr/local/bin
  fi

  if [ ! -x "$(command -v "$HELM_BINARY")" ]; then
    wget https://get.helm.sh/helm-v3.5.3-${os}-amd64.tar.gz -P /tmp/helm
    tar xvzf /tmp/helm/helm-v3.5.3-${os}-amd64.tar.gz
    mv ${os}-amd64/helm helm
    chmod +x helm && sudo mv helm /usr/local/bin
  fi
}

# check architecture - darmin or amd64

if [[ `uname` == 'Linux' ]]; then
   bootstrap "Linux"
else
  if [[ `uname` == 'Darwin' ]]; then
   bootstrap "Darwin"
 fi
fi

# common install

# create k3d cluster
k3d cluster create ${CLUSTER_NAME} --registry-create --api-port 127.0.0.1:6443 -p 80:80@loadbalancer \
-p 443:443@loadbalancer --k3s-server-arg "--no-deploy=traefik"

# pull images locally
docker pull rancher/metrics-server:${RANCHER_METRICS_SERVER} > /dev/null 2>&1 &
docker pull rancher/klipper-lb:${RANCHER_KLIPPER_VERSION} > /dev/null 2>&1 &
docker pull localstack/localstack:${LOCALSTACK_VERSION} > /dev/null 2>&1 &
docker pull traefik:${TRAEFIK_VERSION} > /dev/null 2>&1 &
docker pull rancher/coredns-coredns:${COREDNS_VERSION} > /dev/null 2>&1 &
docker pull k8s.gcr.io/kube-state-metrics/kube-state-metrics:${KUBESTATE_METRICS_VERSION} > /dev/null 2>&1 &
docker pull quay.io/prometheus/alertmanager:${PROMETHEUS_ALERT_MANAGER_VERSION} > /dev/null 2>&1 &
docker pull quay.io/prometheus/node-exporter:${NODE_EXPORTER_VERSION} > /dev/null 2>&1 &
docker pull quay.io/prometheus/prometheus:${PROMETHEUS_VERSION} > /dev/null 2>&1 &
docker pull jimmidyson/${CONFIGMAP_RELOAD_VERSION} > /dev/null 2>&1 &

echo -n "${LIGHTRED}[!] ${WHITE}Waiting for docker to pull all images "

while ps ax | grep -v grep | grep "docker pull" > /dev/null
do
    echo -n "."
    sleep 5
done

echo

# load local images into cluster
k3d image import --cluster ${CLUSTER_NAME} rancher/metrics-server:${RANCHER_METRICS_SERVER} \
    rancher/klipper-lb:${RANCHER_KLIPPER_VERSION} rancher/coredns-coredns:${COREDNS_VERSION} \
     localstack/localstack:${LOCALSTACK_VERSION} traefik:${TRAEFIK_VERSION} \
     k8s.gcr.io/kube-state-metrics/kube-state-metrics:${KUBESTATE_METRICS_VERSION} \
     quay.io/prometheus/node-exporter:${NODE_EXPORTER_VERSION} \
     quay.io/prometheus/alertmanager:${PROMETHEUS_ALERT_MANAGER_VERSION} \
     quay.io/prometheus/prometheus:${PROMETHEUS_VERSION} \
     jimmidyson/${CONFIGMAP_RELOAD_VERSION}

# create localstack setup
kubectl apply -f ops/yaml/localstack/deployment.yaml
kubectl apply -f ops/yaml/localstack/ingress.yaml
kubectl apply -f ops/yaml/localstack/service.yaml

# setup helm charts

# add repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

kubectl create ns lens-metrics

helm install prometheus prometheus-community/prometheus --namespace lens-metrics
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm install kube-state-metrics kube-state-metrics/kube-state-metrics -n lens-metrics --namespace lens-metrics

helm install traefik traefik/traefik

# give access to traefik dashboard

# create localstack setup
kubectl apply -f ops/yaml/traefik/dashboard.yaml
