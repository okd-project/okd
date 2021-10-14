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

Other nodes are instructed to run `machine-config-firstboot.service` early, which does the same for control plane / workers.
TODO: fix installer to include log from this service in log bundles

TODO: Describe most important containers here - `etcd`, `kube-api`, `machine-config-server` etc.

### Fedora CoreOS Image 

To verify the intended Fedora CoreOS image is used, check:
 - Bootstrap nodes: `bootstrap/rpm-ostree/status`
 - For control plane nodes: `control-plane/<node ip>/rpm-ostree/status`
 
~~~
$ cat bootstrap/rpm-ostree/status 
State: idle
Deployments:
* pivot://registry.ci.openshift.org/origin/4.6-2021-08-04-030013@sha256:9f512c61f4077be799a6d7ec2d01aea503cb2ab0c5a93a6e9fc51b5d2bbccb44
              CustomOrigin: Managed by machine-config-operator
                 Timestamp: 2021-05-07T07:33:09Z

  ostree://fedora:fedora/x86_64/coreos/stable
                   Version: 33.20210117.3.2 (2021-02-03T18:13:41Z)
                    Commit: 20de1953c18bd432a8ed4e19b91c64978100dba7d1c4813f91f8cf4d4d2411b4
              GPGSignature: Valid signature by 963A2BEB02009608FE67EA4249FD77499570FF31

$ cat control-plane/10.0.0.7/rpm-ostree/status 
State: idle
Deployments:
* pivot://registry.ci.openshift.org/origin/4.6-2021-08-04-030013@sha256:9f512c61f4077be799a6d7ec2d01aea503cb2ab0c5a93a6e9fc51b5d2bbccb44
              CustomOrigin: Managed by machine-config-operator
                 Timestamp: 2021-05-07T07:33:09Z
           LayeredPackages: NetworkManager-ovs glusterfs glusterfs-fuse qemu-guest-agent

  ostree://fedora:fedora/x86_64/coreos/stable
                   Version: 33.20210117.3.2 (2021-02-03T18:13:41Z)
                    Commit: 20de1953c18bd432a8ed4e19b91c64978100dba7d1c4813f91f8cf4d4d2411b4
              GPGSignature: Valid signature by 963A2BEB02009608FE67EA4249FD77499570FF31
~~~
