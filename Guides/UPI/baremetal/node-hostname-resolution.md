Resolving the Node Hostname
---

# Background
Nodes require a correctly configured hostname in order to join and remain a fully functional cluster member. The hostname is used to generate certificates and also figure out what to call itself.

The OKD installation docs mention that setting valid PTR records will allow the system to automatically detect the hostname. This does not seem to consistently be the case. In addition you may be in an environment where you are unable to edit PTR records.

You may find that although initially when nodes boot the hostname is resolved correctly (e.g via PTR), at some point during the installation process this ability is lost and the node reverts to the `fedora` hostname.

If your nodes are resolving to the `fedora` hostname, you must take steps to rectify this in order for you cluster to be functional.

If during the cluster bootstrap phase any of your nodes come up with the `fedora` hostname, you will need to reprovision that node - it's not worth trying to recover or force a certificate regeneration.

# Resolution
We will introduce a systemd service via MachineConfigs which will resolve the hostname and ensure the system hostname is set correctly, early enough within the node startup.

These MachineConfig manifests will need to be created prior to deploying the cluster. In addition we will need to modify the bootstrap ignition to ensure that the service is deployed there as well.

## Create MachineConfigs and add to manifests
Assuming you are following the docs guide this step occurs in the "Creating the Kubernetes manifest and Ignition config files". You need to do this step after running `openshift-install create manifests` but prior to running `openshift-install create ignition-configs`

Your installer directory should have the folders `manifests` and `openshift` present.

Create a new file called `okd-configure-master-node-hostname.yaml` in the `manifests` folder:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: okd-configure-worker-node-hostname
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
        - contents:
            # See below on writing your hostname resolution script
            source: data:text/plain;charset=utf-8;base64,<YOUR_BASE64_HERE>
          mode: 493
          overwrite: true
          path: /usr/local/bin/okd-resolve-node-hostname.sh
    systemd:
      units:
        - name: okd-configure-hostname.service
          enabled: true
          contents: |
            [Unit]
            Description=Resolve and Set Node Hostname
            # Removal of this file signals firstboot completion
            ConditionPathExists=!/etc/hostname
            # Block services relying on Networking being up.
            Before=network-online.target
            # Wait for NetworkManager to report its online
            After=NetworkManager-wait-online.service
            # Run before hostname checks
            Before=node-valid-hostname.service
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStartPre=/usr/local/bin/okd-resolve-node-hostname.sh
            ExecStart=/bin/bash -c "hostnamectl set-hostname `cat /run/okd-node-hostname`"
            [Install]
            # This makes sure the systemd file is linked correctly
            WantedBy=network-online.target
```

### Creating your `okd-resolve-node-hostname.sh`
The script must create a file at `/run/okd-node-hostname` which is the FQDN for this node (e.g `master1.cluster.example.com`)

The exact details of what this script needs to contain will vary depending on your setup. You may want to call an inventory API, perform a PTR lookup based off an IP or whatever suits your needs.

This is an example `okd-resolve-node.hostname.sh` which uses the publically accessible IP of the node to perform a PTR lookup and save the result to the file.

```bash
#!/bin/bash

myip=$(dig +short myip.opendns.com @208.67.222.222 -4) || myip=$(dig +short txt o-o.myaddr.l.google.com @ns1.google.com -4 | sed s/\"//g)
myhost=$(dig +short -x ${myip} @208.67.222.222 | sed 's/\.$//' ) || myhost=$(dig +short -x ${myip} @8.8.8.8 | sed 's/\.$//')

echo -n ${myhost} > /run/okd-node-hostname
```

When you have a script which works for your usecase you need to base64 encode the file and include it in the yaml as above (if you're doing this a lot look into [installer workspace](installer-workspace.md)).

Finally, we need to replicate the MachineConfig for the worker nodes where relevant. If you are deploying a 3-node-cluster you can skip this step. If you are deploying a cluster with multiple or customised worker types, you will need a MachineConfig for each type.

Copy the MachineConfig to a new file:
`cp okd-configure-master-node-hostname.yaml okd-configure-worker-node-hostname.yaml`

Modify the top of the file to target worker nodes and update the MachineConfig name:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: okd-configure-worker-node-hostname
spec: ...
```

## Edit `bootstrap.ign`

> Editing the `bootstrap.ign` file is generally not recommended. Depending on your setup you may find it safer and easier to use `ignition.config.merge` as documented in the [Ignition specification](https://github.com/coreos/ignition/blob/master/docs/configuration-v3_2.md).

The MachineConfig yaml files will only effect the master and worker nodes. The bootstrap is a snow flake and so you need to manually inject the DNS configuration into the rendered ignition.

This step occurs after you have run `openshift-install create ignition-configs`.

You need to "merge" the following JSON with the JSON within `bootstrap.ign`. You can do this by hand or by using a tool like `jq` or `yq` as in the [installer workspace](installer-workspace.md).

```json
{
  "storage": {
    "files": [
      {
        "overwrite": true,
        "path": "/usr/local/bin/okd-resolve-node-hostname.sh",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain;charset=utf-8;base64,<INJECT_YOUR_BASE_64_HERE>"
        },
        "mode": 493
      }
    ]
  },
  "systemd": {
    "units": [
      {
        "contents": "[Unit]\nDescription=Resolve and Set Node Hostname\n# Removal of this file signals firstboot completion\nConditionPathExists=!/etc/hostname\n# Block services relying on Networking being up.\nBefore=network-online.target\n# Wait for NetworkManager to report its online\nAfter=NetworkManager-wait-online.service\n# Run before hostname checks\nBefore=node-valid-hostname.service\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStartPre=/usr/local/bin/okd-resolve-node-hostname.sh\nExecStart=/bin/bash -c \"hostnamectl set-hostname `cat /run/okd-node-hostname`\"\n[Install]\n# This makes sure the systemd file is linked correctly\nWantedBy=network-online.target",
        "enabled": true,
        "name": "okd-configure-hostname.service"
      }
    ]
  }
}
```

You will need to provide the base64 of the `okd-resolve-node-hostname.sh` file here again. If you need to make specific alterations for the boostrap machine (or if you want to cheat and hardcode it) then you may need to deploy a special version of the script for Bootstrap machine only.
