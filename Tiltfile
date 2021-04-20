# -*- mode: Python -*-

k8s_yaml(helm('ops/helm/test', name='test',values='ops/helm/test/values.yaml'))

# The helm() call above is functionally equivalent to the following:
#
# k8s_yaml(local('helm template -f ./values-dev.yaml ./busybox'))
# watch_file('./busybox')
# watch_file('./values-dev.yaml')

docker_build('test', 'backend')

# 'busybox-deployment' is the name of the Kubernetes resource we're deploying.
k8s_resource('test', port_forwards='8080:80')
