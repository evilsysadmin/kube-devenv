#!/usr/bin/env bash

echo -e "waiting for traefik pod"

while [[ $(kubectl get pods -l app.kubernetes.io/name=traefik -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000 > /dev/null &

echo -e ""

echo -e "waiting for prometheus pods"

while [[ $(kubectl get pods -n lens-metrics -l app=prometheus -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True True True True" ]]; do echo -n "." && sleep 1; done

echo -e ""

echo -e "waiting for localstack pod"

while [[ $(kubectl get pods -l app=localstack -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
