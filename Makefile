K3D_VERSION = v4.2.0
SKAFFOLD_VERSION = 1.20.0
K9S_VERSION = v0.24.2

install-k3d:
	./ops/scripts/install-k3d.sh ${K3D_VERSION} ${SKAFFOLD_VERSION}

delete-k3d:
	k3d cluster delete devcluster
	docker rm registry.local -f

bootstrap: install-k3d
	docker container run -d --name registry.local -v local_registry:/var/lib/registry --restart always -p 5000:5000 registry:2
	k3d cluster create devcluster --api-port 127.0.0.1:6443 -p 80:80@loadbalancer -p 443:443@loadbalancer --k3s-server-arg "--no-deploy=traefik"
	#helm repo add traefik https://containous.github.io/traefik-helm-chart
	helm repo add traefik https://helm.traefik.io/traefik
	helm install traefik traefik/traefik
	ops/scripts/./traefik-forward.sh

dev:
	skaffold dev

run:
	skaffold run
