#!/bin/bash

K3D_VERSION=$1
SKAFFOLD_VERSION=$2
K9S_VERSION=$3

K9S_BINARY="k9s"
K3D_BINARY="k3d"
SKAFFOLD_BINARY="skaffold"

#set -x

#set -x
if [ ! -x "$(command -v "$K9S_BINARY")" ]; then
  sudo wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz -O /tmp/k3d
  sudo chmod +x /tmp/k3d
fi

if [ ! -x "$(command -v "$K3D_BINARY")" ]; then
  sudo wget https://github.com/rancher/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64 -O /tmp/k3d
  sudo chmod +x /tmp/k3d
fi

if [ ! -x "$(command -v "$SKAFFOLD_BINARY")" ]; then

  curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64 && chmod +x skaffold
  sudo mv skaffold /tmp/
fi
