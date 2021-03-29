#!/usr/bin/env bash
HOST_LIST=$1

for host in $(echo $HOST_LIST | sed "s/,/ /g")
do

    if [[ `uname` == 'Linux' ]]; then
      hostline="$(kubectl get svc -l app.kubernetes.io/name=traefik | awk {'print $4'} | tail -1)"
      # delete existing host entries for same domains
      sudo -- bash -c "sed -i '/${host}/d' /etc/hosts"

    fi

    if [[ `uname` == 'Darwin' ]]; then
      hostline="127.0.0.1"
      sudo sed -i '' "/${host}/d" /etc/hosts
    fi

    sudo -- bash -c "echo $hostline $host>> /etc/hosts"
done
