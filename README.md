###  Kubernetes dev environment

- Deploys a k3d cluster ,and local image registry with helm
- creates cluster load balancer

#### Tooling requirements

- k9s
- k3d
- Tilt
- Docker desktop

The makefile flow tries to ensure tooling is available locally. (except Docker desktop)

#### Network requirements

- Cluster listens locally on:
  - tcp 6443
  - tcp 80
  - tcp 443

#### Init

```bash
make bootstrap # to download the tooling, if needed ,and setup the cluster. This will take a few minutes on first run.

K3d will make kubeconfig point automatically to new k3d cluster

```

You can ignore the warnings like:

W0706 16:55:33.456220   36596 warnings.go:70] apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition

Those are coming from traefik , they need to update their CRD config.

#### Workflow

* run k9s from another window # to open a new shell tab , connecting to the local k3d cluster with k9s

* run make dev , to apply the Tiltfile in your local cluster. After running this , hit the spacebar.
  This will open a browser session, in which you can see the deployments status, as well as see logs etc.

  Note : first run will take some time to complete.

  * Make some changes to `index.js`:
      * The file will be synchronized to the cluster
      * `nodemon` will restart the application

  * Make some changes to `package.json`:
      * The full build/push/deploy process will be triggered, fetching dependencies from `npm`

* A single ingress host is created , for "test.com". /etc/hosts updates are automatically managed from makefile.

  So you can test it with

$ curl test.com
  Hello World!!!!!

* Run make nodev , to kill the local devenv.

* And delete your local cluster , with make delete-k3d

### Extra cluster features

You can deploy extra tooling in the cluster , with parameters in extras.yaml

```
k3d:
  prometheus: false
  localstack: true
  elastic: true
  traefik: true
```

Currently this project supports:

- prometheus
- localstack aws
- elasticsearch cluster
- traefik

I will add more tooling , and more docs soon.

# Troubleshooting

If everything fails , if all hope is lost . If the only option is to watch chuck norris movies, check this section.

- I cannot start the devenv! says cluster already exists or something

k3d cluster list

And see what it shows.

#### Traefik dashboard

Exposed at http://traefik.localhost/dashboard/