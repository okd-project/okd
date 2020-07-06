# Frequently Asked Questions

## Where can I find upgrades?
https://origin-release.svc.ci.openshift.org/

> Bug: Take care that if you upgraded to a version which is a nightly, that they get   
 deleted automatically after 48 hours from the CI registry. You could come 
 into a situation where there is no tested upgrade path to a newer version. The removed images may result in pods stuck in ImagePullBackoff (because the pod tries to download an image from the CI registry which isn't available anymore).

> Builds marked with an asterisk won't be pruned


## How can I upgrade my cluster to a new version?
Find a version where a tested upgrade path is available from your version for on 

https://origin-release.svc.ci.openshift.org

Upgrade options:

**Preferred** ways:
* Web Console: Home -> Overview -> Tab: Cluster, Card: Overview -> View settings -> Update Status

  Currently (as of 2020-04-10) this doesn't work because the nightly builds are not signed. Will be resolved soon as of https://github.com/openshift/okd/issues/138) !

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

This will take a while ...

## Interesting commands while an upgrade runs

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

## What to do in case of errors ?
If you experience problems during the installation or afterwards, collect data of your cluster with:

```
oc adm must-gather
```

A directory with lots of information will be created. Tar zip it and and it to the developers.

Cloud provider secrets, ... will not be included.

Upload it to a file hoster and send the link to the developers (Slack channel, ...)

# External tips for OKD 4

* slack:

  Workspace: Kubernetes, Channel: **#openshift-dev** (for **developer** communication)

  Workspace: Kubernetes, Channel: **#openshift-user** (for **users**)
  
* https://openshift.tips/
