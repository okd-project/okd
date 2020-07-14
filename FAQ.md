Frequently Asked Questions

- [What are the relations with OCP project? Is OKD4 being upstream for OCP?](#what-are-the-relations-with-ocp-project-is-okd4-being-upstream-for-ocp)
- [How stable is OKD4?](#how-stable-is-okd4)
- [Can I ran a single node cluster?](#can-i-ran-a-single-node-cluster)
- [Where can I find upgrades?](#where-can-i-find-upgrades)
- [How can I upgrade my cluster to a new version?](#how-can-i-upgrade-my-cluster-to-a-new-version)
- [Interesting commands while an upgrade runs](#interesting-commands-while-an-upgrade-runs)
- [How can I find out what's inside of a (CI) release and which commit id each component has?](#how-can-i-find-out-whats-inside-of-a-ci-release-and-which-commit-id-each-component-has)
- [How can I enable the (non-community) Red Hat Operators?](#how-can-i-enable-the-non-community-red-hat-operators)
- [What to do in case of errors?](#what-to-do-in-case-of-errors)
- [External tips for OKD 4](#external-tips-for-okd-4)

## What are the relations with OCP project? Is OKD4 being upstream for OCP?

In 3.x release time OKD was used as an upstream project for Openshift Container Platform. OKD could be installed on 
Fedora/CentOS/RHEL and used CentOS based images to install the cluster. However OCP could be installed on RHEL only and it rebuilt all the images so that these would be RHEL-based.

[Universal Base Image project](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) has enabled us to run RHEL-based images on any platform, so the full image rebuilt is no longer necessary. This allows OKD4 project to reuse most images from OCP4. However OCP also has another critical part - Red Hat RHEL CoreOS. Although its an opensource project (since its essentially RHEL8) its not a community-driven project. As a result OKD workgroup has 
made a decision to use Fedora CoreOS - opensource and community-driven project - as a base for OKD4. This decisions allows end-user modify all parts of the cluster using prepared instructions.

Note, that OKD4 is being automatically built from OCP [ci stream](https://github.com/openshift/release/blob/1b5147b525b60b9e402a480db6aaf0b8f12960de/core-services/release-controller/_releases/release-ocp-4.5-ci.json#L10-L36), so most of the tests are happening in OCP CI and being mirrored to OKD. As a result, OKD CI doesn't have to run a lot of tests to ensure the release is valid.

These relationships are more complex than "upstream-downstream", so we use "sibling distributions" to describe its state.

## How stable is OKD4?

OKD4 builds are being automatically tested by [release-controller](https://origin-release.svc.ci.openshift.org/). Release is rejected if either installation, upgrade from previous version or conformance test fails. Test results determine the upgrade graph, so, for instance, if upgrade tests passed for beta5->rc edge, clusters on beta5 can be directly updated to rc release, bypassing beta6.

Biweekly OKD stable version is released, following Fedora CoreOS schedule, client tools are uploaded to Github and images are mirrored to Quay.

## Can I ran a single node cluster?

Yes.

Set the following in install config:
```
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 1
```
This would inject nonHA manifest for etcd and run a single ingress pod.

WARNING: this cluster cannot be upgraded or adjusted via MachineConfigs. Adding more masters is not yet supported.

## Where can I find upgrades?
https://origin-release.svc.ci.openshift.org/

Note that nightly builds (from `4.x.0-0.okd`) are pruned every 72 hours. If your cluster uses these images
consider [mirroring](https://docs.okd.io/latest/installing/install_config/installing-restricted-networks-preparations.html#installing-restricted-networks-preparations) these files to a local registry. Builds from `stable-4` stream are not removed

## How can I upgrade my cluster to a new version?
Find a version where a tested upgrade path is available from your version for on 

https://origin-release.svc.ci.openshift.org

Upgrade options:

**Preferred** ways:
* Web Console: Home -> Overview -> Tab: Cluster, Card: Overview -> View settings -> Update Status

* Shell:
  Upgrades to latest available version
  ```
  oc adm upgrade
  ```

**Last resort**:

Upgrade to a certain version (will ignore the update graph!)

  ```
  oc adm upgrade --force --allow-explicit-upgrade=true --to-image=registry.svc.ci.openshift.org/origin/release:4.4.0-0.okd-2020-03-16-105308
  ```

This will take a while, the upgrade may take several hours. Throughout the upgrade kubernetes API would still be 
accessible and user workloads would be evicted and rescheduled if node requires to be updated.

## Interesting commands while an upgrade runs

Check overall upgrade status:
```
oc get clusterversion
```

Check the status of your cluster operators:
```
oc get co
```

Check the status of your nodes (upgrade may include an upgrade to Fedora CoreOS):
```
oc get nodes
```

## How can I find out what's inside of a (CI) release and which commit id each component has?
This one is very helpful if you want to know, if a certain commit has landed in your current version:

  ```
  oc adm release info registry.svc.ci.openshift.org/origin/release:4.4  --commit-urls
  ```

  ```
  Name:      4.4.0-0.okd-2020-04-10-020541
  Digest:    sha256:79b82f237aad0c38b5cdaf386ce893ff86060a476a39a067b5178bb6451e713c
  Created:   2020-04-10T02:14:15Z
  OS/Arch:   linux/amd64
  Manifests: 413

  Pull From: registry.svc.ci.openshift.org/origin/release@sha256:79b82f237aad0c38b5cdaf386ce893ff86060a476a39a067b5178bb6451e713c

  Release Metadata:
    Version:  4.4.0-0.okd-2020-04-10-020541
    Upgrades: <none>

  Component Versions:
    kubernetes 1.17.1
    machine-os 31.20200407.20 Fedora CoreOS

  Images:
    NAME                                           URL
    aws-machine-controllers                        https://github.com/openshift/cluster-api-provider-aws/commit/5fa82204468e71b44f65a5f24e2675dbfa0f5c29
    azure-machine-controllers                      https://github.com/openshift/cluster-api-provider-azure/commit/832a43a30d7f00cd6774c1f5cd117aeebbe1b730
    baremetal-installer                            https://github.com/openshift/installer/commit/a58f24b0df7e3699b39d4ae1d23c45672706934d
    baremetal-machine-controllers
    baremetal-operator
    baremetal-runtimecfg                           https://github.com/openshift/baremetal-runtimecfg/commit/09850a724d9290ffb05db3dd7f4f4c748b982759
    branding                                       https://github.com/openshift/origin-branding/commit/068fa1eac9f31ffe13089dd3de2ec49c153b2a14
    cli                                            https://github.com/openshift/oc/commit/2576e482bf003e34e67ba3d69edcf5d411cfd6f3
    cli-artifacts                                  https://github.com/openshift/oc/commit/2576e482bf003e34e67ba3d69edcf5d411cfd6f3
    cloud-credential-operator                      https://github.com/openshift/cloud-credential-operator/commit/446680ed10ac938e11626409acb0c076edd3fd52
    ...

  ```

## How can I enable the (non-community) Red Hat Operators?
If you have installed OKD with an "official" pull secret which contains ```registry.redhat.io```,
such as that with which you can install OpenShift, you are entitled to enable the Red Hat operators
alongside the default community operators.

One reason for doing so, is to enable the "metering-ocp" operator, as the community operators ships
with a deprecated "metering" operator.

Firstly, ensure that you do have a pull secret which contains ```registry.redhat.io```

Then, update the OperatorHub CR:

```bash
(
cat <<EOF
apiVersion: config.openshift.io/v1
kind: OperatorHub
metadata:
  name: cluster
spec:
  disableAllDefaultSources: true
  sources:
  - disabled: false
    name: redhat-operators
  - disabled: false
    name: community-operators
EOF
 ) | oc apply -f -
```

## What to do in case of errors?
If you experience problems during installation you *must* collect bootstrap log bundle, see [instructions](https://docs.okd.io/latest/installing/installing-troubleshooting.html)

If you experience problems post installation, collect data of your cluster with:

```
oc adm must-gather
```

See [documentation](https://docs.okd.io/latest/support/gathering-cluster-data.html) for more information.

Upload it to a file hoster and send the link to the developers (Slack channel, ...)

During installation SSH key is required. It can be used to ssh on the nodes later on - `ssh core@<node ip>`

## External tips for OKD 4

* slack:

  Workspace: Kubernetes, Channel: **#openshift-dev** (for **developer** communication)

  Workspace: Kubernetes, Channel: **#openshift-user** (for **users**)

* https://openshift.tips/
