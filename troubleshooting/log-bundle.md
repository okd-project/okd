# What log-bundle is and how to read it

## How to collect a log bundle

https://docs.okd.io/latest/installing/installing-troubleshooting.html

## Data included in log bundle

Manifests
Systemd logs from bootstrap / masters
Container inspect / logs

## Where to start reading a log bundle

### Payload and installer version
Firstly it's crucial to ensure the installer and release payload versions match:
```
$ oc adm release info registry.ci.openshift.org/origin/release:4.8 --commits | grep installer
  baremetal-installer                            https://github.com/vrutkovs/installer                                       4b15f0537ad76206c8ba9ba042b404f8c00a295a
  installer                                      https://github.com/vrutkovs/installer                                       4b15f0537ad76206c8ba9ba042b404f8c00a295a
  installer-artifacts                            https://github.com/vrutkovs/installer                                       4b15f0537ad76206c8ba9ba042b404f8c00a295a
```
This command returns the expected commit used to build an installer.

When the cluster is being installed, installer is recording information about itself in the ConfigMap:
```
$ cat rendered-assets/openshift/openshift/openshift-install-manifests.yaml
apiVersion: v1
data:
  invoker: openshift-internal-ci/release-openshift-okd-installer-e2e-aws-upgrade/1396004378611027968
  version: unreleased-master-4619-g4b15f0537ad76206c8ba9ba042b404f8c00a295a
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: openshift-install-manifests
  namespace: openshift-config
```

The format of the `invoker` field is `unreleased-<branch>-<number of commits>-g<commit hash>`. As you can see,
commit hashes are matching, so a valid installer was used to run this cluster.

### Release image

To verify that a correct release payload was used check `bootstrap/journals/release-image.log`:
```
-- Journal begins at Sat 2021-05-22 07:32:02 UTC, ends at Sat 2021-05-22 08:06:41 UTC. --
May 22 07:34:45 ip-10-0-6-51 systemd[1]: Starting Download the OpenShift Release Image...
May 22 07:34:45 ip-10-0-6-51 release-image-download.sh[762]: Pulling registry.build01.ci.openshift.org/ci-op-fggt4c0x/release@sha256:c843adfb4bddd22f7256325ed387d9a685be451ca6d708a56ecb8e8a738b7892...
May 22 07:34:46 ip-10-0-6-51 podman[813]: 2021-05-22 07:34:46.474241096 +0000 UTC m=+0.476275595 system refresh
May 22 07:34:46 ip-10-0-6-51 podman[813]: 2021-05-22 07:34:46.807049267 +0000 UTC m=+0.809083790 image pull  
May 22 07:34:46 ip-10-0-6-51 release-image-download.sh[813]: cfd14e030756425d5f7b09f44926c50c87256f5dd75303f845c27e22790d423e
May 22 07:34:46 ip-10-0-6-51 systemd[1]: Finished Download the OpenShift Release Image.
```

It should be inspectable with `oc adm release info <payload pullspec>`.

### Bootstrap process

https://github.com/openshift/installer/blob/master/docs/user/troubleshootingbootstrap.md

### How OKD bootstrap is different from OCP
There is a significant difference between OCP and OKD boostrap - OCP nodes are RHEL CoreOS and OKD runs on Fedora CoreOS.
RHEL CoreOS is specifically designed to run OpenShift, so it already includes kubelet, crio and Machine Config Daemon.

Fedora CoreOS is more verstile, so OKD runs its own Fedora CoreOS flavor with necessary binaries added. The first step bootstrap
does after release image has been downloaded is updating plain FCOS to OKD content.
This is done in `release-image-download.service` by pulling `machine-os-content` image from 
the payload, extracting ostree commit and pivoting bootstrap into it.
TODO: fix installer to include log from this service.
TODO: find an easy way to identify initial FCOS image used (extract it from the boot log)?

Other nodes are instructed to run `machine-config-firstboot.service` early, which does the same for control plane / workers.
TODO: fix installer to include log from this service in log bundles

TODO: Describe most important containers here - `etcd`, `kube-api`, `machine-config-server` etc.
