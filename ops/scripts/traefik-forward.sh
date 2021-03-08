#!/bin/bash

echo "waiting for traefik pod"

while [[ $(kubectl get pods -l app.kubernetes.io/name=traefik -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000 > /dev/null &
