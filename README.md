###  Skaffold POC example -Node.js with hot-reload

- deploys with helm , in local k3d cluster + local image registry
- creates cluster load balancer

Simple example based on Node.js demonstrating the file synchronization mode.

#### Assumptions

POC created using a linux box. Will differ a lot on Darwin (OSX). Adjust as needed

#### Tooling

- k9s
- k3d
- skaffold

The makefile flow tries to ensure tooling is available locally . Again for linux amd64 arch

#### Init

```bash
make bootstrap # to download the tooling, if needed ,and setup the cluster. This will take a few minutes on first run.

K3d will make kubeconfig point automatically to new k3d cluster

```

#### Workflow

* run k9s from another window # to open a new shell tab , connecting to the local k3d cluster with k9s

* run make dev , to be allow to do live changes , that are going to be deployed live to your local cluster.

  * Make some changes to `index.js`:
      * The file will be synchronized to the cluster
      * `nodemon` will restart the application

  * Make some changes to `package.json`:
      * The full build/push/deploy process will be triggered, fetching dependencies from `npm`

* Otherwise run make run , which will deploy your app in your cluster, without live reload.

* A single ingress host is created , for "test.com". You can test it with

$ curl -H 'Host: test.com' localhost

* delete your local cluster with make delete-k3d
