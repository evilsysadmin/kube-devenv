#!/usr/bin/env bash
CLUSTER_NAME=$1
KUBECTL_VERSION=1.20.0
K3D_VERSION=v4.4.8
TILT_VERSION=0.22.9
K9S_VERSION=v0.24.15
LOCALSTACK_VERSION=0.12.7
TRAEFIK_VERSION=2.5.3
COREDNS_VERSION=1.6.9
KUBESTATE_METRICS_VERSION=v1.9.8
RANCHER_METRICS_SERVER=v0.3.6
RANCHER_KLIPPER_VERSION=v0.2.0
RANCHER_LOCAL_PATH_PROVISIONER=v0.0.14
RANCHER_PAUSE_VERSION=3.1
PROMETHEUS_ALERT_MANAGER_VERSION=v0.21.0
CONFIGMAP_RELOAD_VERSION=configmap-reload:v0.5.0
NODE_EXPORTER_VERSION=v1.0.1
PROMETHEUS_VERSION=v2.24.0
HELM_VERSION=v3.5.3
ELASTIC_VERSION=7.12.0

K9S_BINARY="k9s"
K3D_BINARY="k3d"
TILT_BINARY="tilt"
HELM_BINARY="helm"

K9S_FILE="k9s_Linux_x86_64.tar.gz"
k3D_FILE="k3d-linux-amd64"
TILT_FILE=".linux.x86_64.tar.gz"
KUBECTL_ARCH="linux"
K9S_ARCH="x86_64.tar.gz"
K9S_OS="Linux"

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# ensure there's no other k3d cluster with the same name already.
# if it is , kill it with fire
function preflightchecks() {

  existingcluster=$(k3d cluster list $CLUSTER_NAME| wc -l)
  if [[ $existingcluster -gt 1 ]]; then
    echo "there is already a $CLUSTER_NAME cluster. Wiping it."
    k3d cluster delete $CLUSTER_NAME
  fi
}

# function to download basic binaries

function bootstrap() {
  echo "bootstrapping system..."
  os=$(echo $1 | tr '[A-Z]' '[a-z]')
  echo $os
  if [[ "$1" == "Darwin" ]]; then
    export K9S_FILE="k9s_Darwin_x86_64.tar.gz"
    export k3D_FILE="k3d-darwin-amd64"
    export TILT_FILE=".mac.x86_64.tar.gz"
    export KUBECTL_ARCH="darwin"
    export K9S_OS="Darwin"

    if [ ! -x "$(command -v "wget")" ]; then
      brew install wget
    fi

  fi

  if [ ! -x "$(command -v "kubectl")" ]; then
      wget https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${KUBECTL_ARCH}/amd64/kubectl -O /tmp/kubectl
      sudo chmod +x /tmp/kubectl
      sudo mv /tmp/kubectl /usr/local/bin
  fi

  if [ ! -x "$(command -v "$K3D_BINARY")" ]; then
    wget https://github.com/rancher/k3d/releases/download/${K3D_VERSION}/$k3D_FILE -O /tmp/k3d
    sudo chmod +x /tmp/k3d
    sudo mv /tmp/k3d /usr/local/bin
  fi

  if [ ! -x "$(command -v "$TILT_BINARY")" ]; then
    wget https://github.com/tilt-dev/tilt/releases/download/v${TILT_VERSION}/tilt.${TILT_VERSION}${TILT_FILE} -P /tmp
    tar xvzf /tmp/tilt.${TILT_VERSION}${TILT_FILE} -C /tmp
    sudo chmod +x /tmp/tilt
    sudo mv /tmp/tilt /usr/local/bin
  fi

  if [ ! -x "$(command -v "$HELM_BINARY")" ]; then
    wget https://get.helm.sh/helm-v3.5.3-${os}-amd64.tar.gz -P /tmp/helm
    tar xvzf /tmp/helm/helm-v3.5.3-${os}-amd64.tar.gz
    mv ${os}-amd64/helm helm
    chmod +x helm && sudo mv helm /usr/local/bin
  fi

  if [ ! -x "$(command -v "$K9S_BINARY")" ]; then
    wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${K9S_OS}_x86_64.tar.gz -P /tmp
    tar xvzf /tmp/${K9S_BINARY}_${K9S_OS}_x86_64.tar.gz -C /tmp
    chmod +x /tmp/k9s && sudo mv /tmp/k9s /usr/local/bin
  fi
}

#################################################################################
## START OF SCRIPT
#################################################################################

# parse features

eval $(parse_yaml extras.yaml)

echo "Creating cluster with the following extra features: "
echo "..."
cat extras.yaml

preflightchecks

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
k3d cluster create ${CLUSTER_NAME} -c cluster_config.yaml
# pull images locally

echo -n "${LIGHTRED}[!] ${WHITE}Waiting for docker to pull all extra images "

docker pull rancher/metrics-server:${RANCHER_METRICS_SERVER} > /dev/null 2>&1 &
docker pull rancher/klipper-lb:${RANCHER_KLIPPER_VERSION} > /dev/null 2>&1 &
docker pull rancher/local-path-provisioner:${RANCHER_LOCAL_PATH_PROVISIONER} > /dev/null 2>&1 &
docker pull rancher/pause:${RANCHER_PAUSE_VERSION} > /dev/null 2>&1 &
docker pull traefik:${TRAEFIK_VERSION} > /dev/null 2>&1 &
docker pull rancher/coredns-coredns:${COREDNS_VERSION} > /dev/null 2>&1 &
docker pull k8s.gcr.io/kube-state-metrics/kube-state-metrics:${KUBESTATE_METRICS_VERSION} > /dev/null 2>&1 &

# pull extra images conditionally
if [ ${k3d_localstack} = true ]
then
  docker pull localstack/localstack:${LOCALSTACK_VERSION} > /dev/null 2>&1 &
fi


if [ ${k3d_prometheus} = true ]
then
  echo "Pulling prometheus images..."
  docker pull quay.io/prometheus/alertmanager:${PROMETHEUS_ALERT_MANAGER_VERSION} > /dev/null 2>&1 &
  docker pull quay.io/prometheus/node-exporter:${NODE_EXPORTER_VERSION} > /dev/null 2>&1 &
  docker pull quay.io/prometheus/prometheus:${PROMETHEUS_VERSION} > /dev/null 2>&1 &
  docker pull jimmidyson/${CONFIGMAP_RELOAD_VERSION} > /dev/null 2>&1 &
fi

if [ ${k3d_elastic} = true ]
then
  docker pull docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION} > /dev/null 2>&1 &
fi

while ps ax | grep -v grep | grep "docker pull" > /dev/null
do
    echo -n "."
    sleep 5
done

echo
set -x
# load local images into cluster
echo "importing host images into cluster image repo..."
# k3d image import --verbose --trace --cluster ${CLUSTER_NAME} rancher/metrics-server:${RANCHER_METRICS_SERVER} \
#     rancher/klipper-lb:${RANCHER_KLIPPER_VERSION} rancher/coredns-coredns:${COREDNS_VERSION} \
#     k8s.gcr.io/kube-state-metrics/kube-state-metrics:${KUBESTATE_METRICS_VERSION} \
#     traefik:${TRAEFIK_VERSION} > /dev/null 2>&1 &
k3d image import -t --cluster ${CLUSTER_NAME} rancher/coredns-coredns:${COREDNS_VERSION}
k3d image import -t --cluster ${CLUSTER_NAME} rancher/pause:${RANCHER_PAUSE_VERSION}
k3d image import -t --cluster ${CLUSTER_NAME} rancher/local-path-provisioner:${RANCHER_LOCAL_PATH_PROVISIONER}
k3d image import -t --cluster ${CLUSTER_NAME} rancher/metrics-server:${RANCHER_METRICS_SERVER}
k3d image import -t --cluster ${CLUSTER_NAME} rancher/klipper-lb:${RANCHER_KLIPPER_VERSION}

k3d image import -t --cluster ${CLUSTER_NAME} traefik:${TRAEFIK_VERSION}
k3d image import --cluster ${CLUSTER_NAME} k8s.gcr.io/kube-state-metrics/kube-state-metrics:${KUBESTATE_METRICS_VERSION}

if [ ${k3d_localstack} = true ]
then
  k3d image import --cluster ${CLUSTER_NAME} localstack/localstack:${LOCALSTACK_VERSION}  > /dev/null 2>&1 &
  # create localstack setup
  kubectl apply -f ops/yaml/localstack/deployment.yaml
  kubectl apply -f ops/yaml/localstack/ingress.yaml
  kubectl apply -f ops/yaml/localstack/service.yaml
fi

if [ ${k3d_prometheus} = true ]
then
  echo "installing prometheus..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  k3d image import --cluster ${CLUSTER_NAME} quay.io/prometheus/node-exporter:${NODE_EXPORTER_VERSION} \
   quay.io/prometheus/alertmanager:${PROMETHEUS_ALERT_MANAGER_VERSION} \
   quay.io/prometheus/prometheus:${PROMETHEUS_VERSION} \
   jimmidyson/${CONFIGMAP_RELOAD_VERSION} > /dev/null 2>&1 &
   kubectl create ns lens-metrics
   helm install kube-state-metrics kube-state-metrics/kube-state-metrics -n lens-metrics
   helm install prometheus prometheus-community/prometheus --namespace lens-metrics
fi

if [ ${k3d_elastic} = true ]
then
  k3d image import --cluster ${CLUSTER_NAME} docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION} > /dev/null 2>&1 &
fi


while ps ax | grep -v grep | grep "k3d image import" > /dev/null
do
    echo -n "."
    sleep 5
done

# setup helm charts
# add repos
helm repo add traefik https://helm.traefik.io/traefik
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics

helm repo update


if [ ${k3d_traefik} = true ]
then
  helm install traefik traefik/traefik --values=ops/yaml/traefik/values.yaml
fi

if [ ${k3d_elastic} = true ]
then
  helm repo add elastic https://helm.elastic.co
  helm install elastic-operator elastic/eck-operator -n elastic-system --create-namespace
  kubectl apply -f ops/yaml/elastic/cluster.yaml
fi
