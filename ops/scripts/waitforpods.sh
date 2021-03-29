#!/usr/bin/env bash

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

eval $(parse_yaml config.yaml)

echo -e "waiting for traefik pod"
while [[ $(kubectl get pods -l app.kubernetes.io/name=traefik -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
echo -e ""

if [ ${k3d_prometheus} = true ]
then

  echo -e "waiting for prometheus pods"
  while [[ $(kubectl get pods -n lens-metrics -l app=prometheus -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True True True True" ]]; do echo -n "." && sleep 1; done
  echo -e ""
fi

if [ ${k3d_localstack} = true ]
then

  echo -e "waiting for localstack pod"
  while [[ $(kubectl get pods -l app=localstack -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
  echo -e ""

fi

if [ ${k3d_elastic} = true ]
then
  echo -e "waiting for elastic pod"
  while [[ $(kubectl get pods -l common.k8s.elastic.co/type=elasticsearch -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo -n "." && sleep 1; done
  echo -e ""
fi
