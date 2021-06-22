HOST_LIST = test.com,test2.com,localstack.local
HADOLINT_VERSION = v1.23.0
CLUSTER_NAME="local-cluster"

lint-image:
	docker run --rm -i hadolint/hadolint:${HADOLINT_VERSION} < backend/Dockerfile

bootstrap:
	./ops/scripts/bootstrap.sh ${CLUSTER_NAME}
	./ops/scripts/./waitforpods.sh
	./ops/scripts/hosts.sh ${HOST_LIST}

delete-k3d:
	k3d cluster delete ${CLUSTER_NAME}
	registrycontainer=`docker ps -a | grep k3d-local-cluster-registry | awk {'print $$1'}`
	echo $registrycontainer
	if [ -z $registrycontainer] then
	 	docker ps -a | grep k3d-local-cluster-registry | awk {'print $$1'} | xargs -n1 docker rm
	fi
	rm -rf ops/terraform/local/.terraform*

list-clusters:
	k3d cluster list

dev:
	tilt up -f tilt/Tiltfile

nodev:
	tilt down -f tilt/Tiltfile

localstack:
	docker run --rm -p 4566:4566 -p 4571:4571 localstack/localstack

nolocalstack:
	docker ps | grep localstack | awk {'print $1'} | xargs -n1 docker rm -f

hosts:
	./ops/scripts/hosts.sh ${HOST_LIST}
