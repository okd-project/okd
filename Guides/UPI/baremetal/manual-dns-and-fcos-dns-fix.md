Manual DNS Configuration and FCOS DNS Fix
===

# Background
Fedora CoreOS (FCOS) 33 changed how the system resolved DNS queries (migrated to systemd-resolve).

This caused regressions in OKD installation which means freshly installed clusters had no functioning DNS when a FCOS 33 image was used.

There is a fix in progress for this issue, please check the related links to see if the fix has been released. If it has been released - please also submit a PR to delete this document!

This document also explores how to push manual DNS configurations to your nodes 

# Related links
- Issues: openshift/okd#477, openshift/okd#440
- Fixes: openshift/machine-config-operator!2359 (not in an OKD release at time of writing)

# Symptoms

On your bootstrap machine you are seeing log lines similar to:

```
Dec 20 09:03:42 bootstrap release-image-download.sh[931]: Pull failed. Retrying quay.io/openshift/okd@sha256:01948f4c6bdd85cdd212eb40d96527a53d6382c4489d7da57522864178620a2c...
Dec 20 09:03:42 bootstrap release-image-download.sh[435268]: Error: Error initializing source docker://quay.io/openshift/okd@sha256:01948f4c6bdd85cdd212eb40d96527a53d6382c4489d7da57522864178620a2c: error pinging docker registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io on [::1]:53: read udp [::1]:60125->[::1]:53: read: connection refused
```
The main giveaway is the `[::1]:53: read udp [::1]:60125->[::1]:53: read: connection refused`

# Hotfix
There are two solutions:
1. Use a FCOS 32 based image for initial installation
2. Apply DNS configuration fixes to your FCOS 33 installation

## Apply manual DNS configuration fixes

This requires manual editing of the OKD manifest files and the generated ignition files for the Bootstrap machine.

### Step 1: Inject DNS MachineConfig
Assuming you are following the docs guide this step occurs in the "Creating the Kubernetes manifest and Ignition config files". You need to do this step after running `openshift-install create manifests` but prior to running `openshift-install create ignition-configs`

Your installer directory should have the folders `manifests` and `openshift` present.

Create a new file called `okd-configure-master-node-dns.yaml` in the `manifests` folder:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: okd-configure-master-node-dns
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      links:
      - path: /etc/resolv.conf
        overwrite: true
        target: ../run/systemd/resolve/resolv.conf
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,W1Jlc29sdmVdCkROU1N0dWJMaXN0ZW5lcj1ubwo=
        mode: 420
        overwrite: true
        path: /etc/systemd/resolved.conf.d/50-no-dns-stub.conf
      # Optional - see notes below
      - contents:
          source: data:text/plain;charset=utf-8;base64,<INJECT_YOUR_BASE_64_HERE>
        mode: 420
        overwrite: true
        path: /etc/systemd/resolved.conf.d/75-static-dns-servers.conf
```

This file does a few things:
- Creates a symlink between /etc/resolv.conf and the systemd generated resolv file. This negates the FCOS regression.
- The `50-no-dns-stub.conf` file prevents systemd trying to create the symlink at runtime, which would fail and. The contents of the base64 are:
```
[Resolve]
DNSStubListener=no
```
- Optionally, you can use statically configure DNS servers if your setup requires that. You will need to locally construct the resolv file and then convert it to base64 (if you're doing this a lot look into [installer workspace](installer-workspace.md))
```
[Resolve]
DNS=9.9.9.9
```
> Note: DHCP DNS will still be added if presented. The DNS server given by DHCP will be appended *after* the statically defined ones so will only be used if the static DNS fails (ie is down - not empty responses).

Finally, we need to replicate the MachineConfig for the worker nodes where relevant. If you are deploying a 3-node-cluster you can skip this step. If you are deploying a cluster with multiple or customised worker types, you will need a MachineConfig for each type.

Copy the MachineConfig to a new file:
`cp okd-configure-master-node-dns.yaml okd-configure-worker-node-dns.yaml`

Modify the top of the file to target worker nodes and update the MachineConfig name:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: okd-configure-worker-node-dns
spec: ...
```

### Step 2: Inject DNS Configuration into the bootstrap
The MachineConfig yaml files will only effect the master and worker nodes. The bootstrap is a snow flake and so you need to manually inject the DNS configuration into the rendered ignition.

This step occurs after you have run `openshift-install create ignition-configs`.

You need to "merge" the following JSON with the JSON within `bootstrap.ign`. You can do this by hand or by using a tool like `jq` or `yq` as in the [installer workspace](installer-workspace.md).

```json
{
  "storage": {
    "links": [
      {
        "group": {},
        "path": "/etc/resolv.conf",
        "user": {},
        "target": "../run/systemd/resolve/resolv.conf"
      }
    ],
    "files": [
      {
        "overwrite": true,
        "path": "/etc/systemd/resolved.conf.d/50-no-dns-stub.conf",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain;charset=utf-8;base64,W1Jlc29sdmVdCkROU1N0dWJMaXN0ZW5lcj1ubwo="
        },
        "mode": 420
      },
      {
        "overwrite": true,
        "path": "/etc/systemd/resolved.conf.d/75-static-dns-servers.conf",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain;charset=utf-8;base64,<INJECT_YOUR_BASE_64_HERE>"
        },
        "mode": 420
      },
    ]
  }
}
```
Here again the `75-static-dns-servers` is optional. You may choose to delete it. If you retain it you will need to provide the base64 encoded string of your resolv file.
