Contributing to OKD4
====

# Introduction into release payloads

Unlike other Kubernetes distributions OKD4 has a strictly defined set of software to be installed:
* It must be installed on a new installation of a supported OS, the setup on already provisioned machines is not supported
* OKD doesn't use RPM repositories
* Strictly controls most control plane details using [operator pattern](https://www.openshift.com/learn/topics/operators).

In order to install OKD4 you need an image, which contains references to all parts - its called 
_**"release payload"**_. It contains an operator (Cluster Version Operator), a list of manifests to 
apply and a reference file. Its contents can be conveniently viewed using `oc` utility:

```
$ oc adm release info registry.svc.ci.openshift.org/origin/release:4.4
Name:      4.4.0-0.okd-2020-04-14-172428
Digest:    sha256:54446b5bcbd5ec702cfa659230d2228932dfca37bd1cb5fe49cdd9ba869f9329
Created:   2020-04-14T17:27:12Z
OS/Arch:   linux/amd64
Manifests: 413

Pull From: registry.svc.ci.openshift.org/origin/release@sha256:54446b5bcbd5ec702cfa659230d2228932dfca37bd1cb5fe49cdd9ba869f9329

Release Metadata:
  Version:  4.4.0-0.okd-2020-04-14-172428
  Upgrades: <none>

Component Versions:
  kubernetes 1.17.1
  machine-os 31.20200407.20 Fedora CoreOS

Images:
  NAME                                           DIGEST
  aws-machine-controllers                        sha256:2a39cd7f86fd2ecc98d65e0a84c93d8263ecf31aafb3d49b138a84192301f092
  azure-machine-controllers                      sha256:81939c4826f3f497833b0761d42ad2e611f7e9180a9117a97ae7f4c78f1fe254
  baremetal-installer                            sha256:05a359b353b330b05a2a2dfaf92fada3769d6bdd30071684dc09e7a23e4fb647
```

The release payload contains references to all the images required to setup a cluster, including `oc` and 
`openshift-install`. These tools can be extracted from the release payload using `oc adm release extract '--command-os=*' --tools --to=/path/to/destination registry.svc.ci.openshift.org/origin/release:4.4` command. Make sure you're using `oc` version 4 to perform this. [Github releases](https://github.com/openshift/okd/releases) or [OCP mirrors](https://mirror.openshift.com/pub/openshift-v4/clients/oc/) have `oc` archives for your platform.

Release payloads are used during updates too - updating OKD4 means pulling a new release payload, running CVO and applying the new manifests, which causes operators to be updated etc.

# Mirroring the images

If the external release image registry is not accessible in your setup, all images can be mirrored 
to a different registry using the `mirror` subcommand:
```
oc adm -a /path/to/pull-secret.json \
  release mirror \
  --from "registry.svc.ci.openshift.org/origin/release:4.4.0-0.okd-2020-03-13-053843" \
  --to quay.io/vrutkovs/okd-content \
  --to-release-image quay.io/vrutkovs/okd-release:4.4
```
This command would copy images, referenced in `registry.svc.ci.openshift.org/origin/release:4.4.0-0.okd-2020-03-13-053843` image to `quay.io/vrutkovs/okd-content` and create a new release image `quay.io/vrutkovs/okd-release:4.4`. The new release image would use `quay.io/vrutkovs/okd-content` as an additional source of images.

`release mirror` command would also print out the mirroring configuration for the installer.

See [installing a cluster on bare metal in a restricted network.](https://docs.okd.io/latest/installing/installing_bare_metal/installing-restricted-networks-bare-metal.html)

# Making changes

`oc adm release` can be used to create new releases, amending existing releases. If one of the images 
needs to be updated use `release new` subcommand.

For example, lets create a new release with updated Prometheus image. Use `release info` command 
to print the pullspec used in the existing image:
```
$ oc adm release info registry.svc.ci.openshift.org/origin/release:4.4 --pullspecs | grep prometheus
  k8s-prometheus-adapter                         registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:12bac47c71cb7ef36b6ee7b78e0476fbfb8a67bbf61ac42c461c17c98ac850a6
  prometheus                                     registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:5af0373659974782379d90d9a174352dd8f85cb7327cc48ef36cae4e8ba5903f
  prometheus-alertmanager                        registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:25bed531ccb0ff16ce19b927265f03cb9b2d572caa224ef302002269e925d83c
  prometheus-config-reloader                     registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:deacbd618b3c037cc8c99a83db2c2a1053db517b0a0bfdfdeb309591559c3eea
  prometheus-node-exporter                       registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:c199e7353642ed1a4237416055a75b0e415034c7ec48bbc8ae8d12b72552f819
  prometheus-operator                            registry.svc.ci.openshift.org/origin/4.4-2020-04-14-172428@sha256:ec28b9dc5ad9184d0d70b85e5bc618c809084b293cbc57c215bf845bf7147b2b
```

With the `release new` command a list of replaced images can be specified:
```
$ oc adm -a /path/to/pull_secret.json \
  release new \
  --from-release registry.svc.ci.openshift.org/origin/release:4.4 \
  --to-image quay.io/vrutkovs/okd-release:4.4-updated-prometheus \
  prometheus=docker.io/prom/prometheus:v2.17.1
```

This command would do the following:

* fetch `--from-release` image and parse image references in it
* replace `prometheus` reference with a new one
* create a new `--to-image` release with updated reference.

`release new` command supports more than one replacement in the cli (separated by the space).

Installer in the new image would also be updated - it would point to the new release:
```
$ oc adm release extract '--command-os=/usr/bin/openshift-install' --to=quay.io/vrutkovs/okd-release:4.4-updated-prometheus
```
This installer would now use this release as a source of truth - and use Prometheus v2.17.1 pulling it from Dockerhub.

# Replacing other images

Images referenced in the release payload are prepared on CI using Openshift builds from git repos (with one exception - `machine-os-content`, see below). In order to find out details about a particular 
image use `--commit-urls`:
```
$ oc adm release info registry.svc.ci.openshift.org/origin/release:4.4 --commit-urls
...
Images:
  NAME                                           URL 
  aws-machine-controllers                        https://github.com/openshift/cluster-api-provider-aws/commit/5fa82204468e71b44f65a5f24e2675dbfa0f5c29
  azure-machine-controllers                      https://github.com/openshift/cluster-api-provider-azure/commit/832a43a30d7f00cd6774c1f5cd117aeebbe1b730
  baremetal-installer                            https://github.com/openshift/installer/commit/e0b9dedd751543fbc01066a3049ff000e60b1459

```
This shows the particular commit used to build these images.

In order to include a change in OKD release you'd need to make code changes and rebuild the image. Most repositories have a `Dockerfile` at the root of the repo - so a simple `podman build` rebuilds it.

If it is not clear which Dockerfile is used to build the image refer to CI configuration: for instance, here's how machine-config-operator image gets built.

Go to `https://github.com/openshift/release/tree/master/ci-operator/config/openshift/<operator repo name>`, where repo name is `machine-config-operator`. Pick the file describing CI config for particular branch - OKD 4.4 uses a forked version located on the `fcos` branch, so it's `openshift-machine-config-operator-fcos.yaml`. In `images` list it mentions that `Dockerfile` is used to build `machine-config-operator` image.

# Building `machine-os-content` image

TDB, see https://github.com/vrutkovs/machine-os-content-builder
