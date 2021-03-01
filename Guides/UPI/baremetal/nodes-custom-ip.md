Setting Custom Node IPs
---

When deploying in non-standard network environments you may need to control what IPs are used by OKD and K8s services to ensure traffic flows over the correct networks/interfaces.

Kubelet and other services used in the bootstrap don't use DNS to resolve IP addresses. An IP is either provided to the Kubelet command or one will be automatically discovered.

By default OKD and K8s services often attempt to auto discover the IP to use based on the routability of each address. In a situation where you have multiple interfaces with valid routes, then the first valid IP will be used by interface order. This means in a system setup where you have `eno1` (routed public network) and `eno2` (routed private network), then the address on the `eno1` network will be used.

> You can look at the runtime resolver for Node IPs [here](https://github.com/openshift/baremetal-runtimecfg/blob/master/cmd/runtimecfg/node-ip.go)

This is a bit of a frustrating/counter-intuitive behaviour, especially if you set DNS records to use private addresses..! However there is a relatively simple solution to influence the IP selection for the node.

# Creating a Node IP service

Both Kubelet and CRI.O allow setting the Node IP via configuration. We will create a service to supply this configuration based off of our own IP-resolution logic, overriding the default node-ip resolution.

We will write a script which resolves our chosen "internal" IP and configures Kubelet and CRIO with our chosen internal IP. We'll write a service to call this after the OKD-default node-ip configuration service has ran, but before Kubelet and CRIO starts.

These scripts and services will be deployed as a MachineConfig. These MachineConfig manifests will need to be created prior to deploying the cluster.

## Create MachineConfigs and add to manifests
Assuming you are following the docs guide this step occurs in the "Creating the Kubernetes manifest and Ignition config files". You need to do this step after running `openshift-install create manifests` but prior to running `openshift-install create ignition-configs`

Your installer directory should have the folders `manifests` and `openshift` present.

Create a new file called `okd-configure-master-node-ip.yaml` in the `manifests` folder:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: okd-configure-master-node-ip
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
        # See below on writing your IP resolution script
          source: data:text/plain;charset=utf-8;base64,<YOUR_BASE64_HERE>
        mode: 493
        overwrite: true
        path: /usr/local/bin/okd-set-node-ip.sh
    systemd:
      units:
      - name: okd-node-ip.service
        enabled: true
        contents: |
          [Unit]
          Description=Overwrites the output of nodeip-configuration.service to replace with our result
          After=nodeip-configuration.service
          Before=kubelet.service crio.service

          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/okd-set-node-ip.sh

          [Install]
          RequiredBy=kubelet.service
```

### Creating your `okd-set-node-ip.sh`
The script must configure Kubelete and CRIO to use your chosen IP. The configuration key for Kubelet is `KUBELET_NODE_IP` and for CRIO it's `CONTAINER_STREAM_ADDRESS`.

The exact details of what this script needs to contain will vary depending on your setup. You may want to call an inventory API, perform a lookup based off a hostname or whatever suits your needs.

This is an example `okd-set-node-ip.sh` which uses the result of `hostname --ip-address` as the primary IP (i.e. resolve the hostname).

```sh
#!/bin/bash
HOSTNAME_RESOLVED_IP=$(hostname --ip-address | sed s/\"//g)
printf "[Service]\nEnvironment=\"KUBELET_NODE_IP=${HOSTNAME_RESOLVED_IP}\"\n" > /etc/systemd/system/kubelet.service.d/20-nodenet.conf
printf "[Service]\nEnvironment=\"CONTAINER_STREAM_ADDRESS=${HOSTNAME_RESOLVED_IP}\"\n" > /etc/systemd/system/crio.service.d/20-nodenet.conf
```

When you have a script which works for your usecase you need to base64 encode the file and include it in the yaml as above (if you're doing this a lot look into [installer workspace](installer-workspace.md)).

Finally, we need to replicate the MachineConfig for the worker nodes where relevant. If you are deploying a 3-node-cluster you can skip this step. If you are deploying a cluster with multiple or customised worker types, you will need a MachineConfig for each type.

Copy the MachineConfig to a new file:
`cp okd-configure-master-node-ip.yaml okd-configure-worker-node-ip.yaml`

Modify the top of the file to target worker nodes and update the MachineConfig name:

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: okd-configure-worker-node-ip
spec: ...
```

### Editing `bootstrap.ign`

> Editing the `bootstrap.ign` file is generally not recommended. Depending on your setup you may find it safer and easier to use `ignition.config.merge` as documented in the [Ignition specification](https://github.com/coreos/ignition/blob/master/docs/configuration-v3_2.md).

The MachineConfig yaml files will only effect the master and worker nodes. The bootstrap is a snow flake and so you need to manually inject the Node IP configuration into the rendered ignition.

This step occurs after you have run `openshift-install create ignition-configs`.

You need to "merge" the following JSON with the JSON within `bootstrap.ign`. You can do this by hand or by using a tool like `jq` or `yq` as in the [installer workspace](installer-workspace.md).

```json
{
  "storage": {
    "files": [
      {
        "overwrite": true,
        "path": "/usr/local/bin/okd-set-node-ip.sh",
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
        "contents": "[Unit]\nDescription=Overwrites the output of nodeip-configuration.service to replace with our result\nAfter=nodeip-configuration.service\nBefore=kubelet.service crio.service\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/okd-set-node-ip.sh\n[Install]\nRequiredBy=kubelet.service",
        "enabled": true,
        "name": "okd-node-ip.service"
      }
    ]
  }
}
```

You will need to provide the base64 of the `okd-set-node-ip.sh` file here again. If you need to make specific alterations for the boostrap machine (or if you want to cheat and hardcode it) then you may need to deploy a special version of the script for Bootstrap machine only.

## Patching the `bootkube.sh` script
The bootstrap machine uses a script `bootkube.sh` to bring up an initial k8s for bootstrapping the three masters.

You may want to force bootstrap traffic to go over your private interface and so services within `bootkube.sh` need to advertise the private IP.

We need to modify the bootstrap of the etcd cluster and the kube-apiserver so that they select the IP which we choose.

This step occurs after you have run `openshift-install create ignition-configs`.

Firstly grab the `bootkube.sh` for your OKD deploy. The safest way to do this is to decode the file as rendered in the `bootstrap.ign`. You can use a tool like `jq` or `yq` to search the ign file (it's JSON) and filter the file object or you can open it up in your preferred text editor and search for the file declaration `"path":"/usr/local/bin/bootkube.sh"`. The file will be encoded in base64 under the key `contents.source` within that object. You will need to decode the base64 into plain text for patching.

We have three things to do:
1. Resolve the IP we want to use for the etcd bootstrap and the kube-apiserver
2. Configure etcd to use the IP we want
3. Configure kube-apiserver to use the IP we want

> In the following snippets please note that it's likely that as OKD updates the script will have minor modifications - please do not copy and paste blocks of code from here into your script - patch with care! For each patch the surroudning lines are provided to help you figure out where in the script each patch is made. 

### Resolve the IP we want

After the other variable declarations we want to resolve the IP we want to be used.

#### `bootkube.sh`
```bash
...
MDNS_PUBLISHER_IMAGE=$(image_for mdns-publisher)
HAPROXY_IMAGE=$(image_for haproxy-router)
BAREMETAL_RUNTIMECFG_IMAGE=$(image_for baremetal-runtimecfg)

### START PATCH - RESOLVE IP ###
PATCH_CUSTOM_IP=$(hostname --ip-address | sed s/\"//g)
### END PATCH - RESOLVE IP ###

mkdir --parents ./{bootstrap-manifests,manifests}

if [ ! -f openshift-manifests.done ]
then
	echo "Moving OpenShift manifests in with the rest of them"
	cp openshift/* manifests/
	touch openshift-manifests.done
fi
...
```
You will likely use very similar logic to what you did in your `okd-set-node-ip.sh`. If your IP resolution is particuarly expensive you could save to file the IP to use within `okd-set-node-ip.sh` and pull it in here.


### Configure etcd bootstrap 

We will modify the etcd bootstrap operator use the custom IP for it's "Bootstrap IP".
This IP is used by the bootstrapped master nodes to figure out where the first etcd instance is before reaching quorom.

> If you're having issues you might want to poke into the [cluster-etcd-operator](https://github.com/openshift/cluster-etcd-operator/) code to see how [bootstrapIP](https://github.com/openshift/cluster-etcd-operator/search?q=bootstrapIP) is used.

#### `bootkube.sh`
```bash
...
ETCD_ENDPOINTS=https://localhost:2379
if [ ! -f etcd-bootstrap.done ]
then
	echo "Rendering CEO Manifests..."
	bootkube_podman_run \
		--volume "$PWD:/assets:z" \
		"${CLUSTER_ETCD_OPERATOR_IMAGE}" \
		/usr/bin/cluster-etcd-operator render \
		--etcd-ca=/assets/tls/etcd-ca-bundle.crt \
		--etcd-ca-key=/assets/tls/etcd-signer.key \
		--manifest-etcd-image="${MACHINE_CONFIG_ETCD_IMAGE}" \
		--etcd-discovery-domain=okd.dev.ccgn.co \
		--manifest-cluster-etcd-operator-image="${CLUSTER_ETCD_OPERATOR_IMAGE}" \
        --asset-input-dir=/assets/tls \
        ### START PATCH - Custom etcd Bootstrap IP ###
        --bootstrap-ip="${PATCH_CUSTOM_IP}" \
        ### END PATCH - Custom etcd Bootstrap IP ###
		--asset-output-dir=/assets/etcd-bootstrap \
		--config-output-file=/assets/etcd-bootstrap/config \
		--cluster-config-file=/assets/manifests/cluster-network-02-config.yml

	cp etcd-bootstrap/manifests/* manifests/
	cp etcd-bootstrap/bootstrap-manifests/etcd-member-pod.yaml /etc/kubernetes/manifests/

	mkdir --parents /etc/kubernetes/static-pod-resources/etcd-member
	cp tls/etcd-ca-bundle.crt /etc/kubernetes/static-pod-resources/etcd-member/ca.crt
	cp --recursive etcd-bootstrap/bootstrap-manifests/secrets/etcd-all-serving /etc/kubernetes/static-pod-resources/etcd-member
	cp --recursive etcd-bootstrap/bootstrap-manifests/secrets/etcd-all-peer /etc/kubernetes/static-pod-resources/etcd-member

	touch etcd-bootstrap.done
fi
...
```

### Configure kube-apiserver bootstrap

We will modify the kube-apiserver bootstrap so that the advertised address of the bootstrap node is the IP of our choosing. We do this by patching the rendered bootstrap configuration.

#### `bootkube.sh`
```bash
...

if [ ! -f kube-apiserver-bootstrap.done ]
then
	echo "Rendering Kubernetes API server core manifests..."

	rm --recursive --force kube-apiserver-bootstrap

	bootkube_podman_run  \
		--volume "$PWD:/assets:z" \
		"${KUBE_APISERVER_OPERATOR_IMAGE}" \
		/usr/bin/cluster-kube-apiserver-operator render \
		--manifest-etcd-serving-ca=etcd-ca-bundle.crt \
		--manifest-etcd-server-urls="${ETCD_ENDPOINTS}" \
		--manifest-image="${OPENSHIFT_HYPERKUBE_IMAGE}" \
		--manifest-operator-image="${KUBE_APISERVER_OPERATOR_IMAGE}" \
		--asset-input-dir=/assets/tls \
		--asset-output-dir=/assets/kube-apiserver-bootstrap \
		--config-output-file=/assets/kube-apiserver-bootstrap/config \
		--cluster-config-file=/assets/manifests/cluster-network-02-config.yml
	
    ### START PATCH - Modify rendered kube-apiserver-bootstrap config ###
	sed -E "s/apiServerArguments:/apiServerArguments:\n  advertise-address:\n  - ${HOSTNAME_RESOLVED_IP}/" kube-apiserver-bootstrap/config
    ### END PATCH - Modify rendered kube-apiserver-bootstrap config ###
	
	cp kube-apiserver-bootstrap/config /etc/kubernetes/bootstrap-configs/kube-apiserver-config.yaml
	cp kube-apiserver-bootstrap/bootstrap-manifests/* bootstrap-manifests/
	cp kube-apiserver-bootstrap/manifests/* manifests/

	touch kube-apiserver-bootstrap.done
fi
...
```

You'll note we are patching a YAML file rendered by the [kube-apiserver operator](https://github.com/openshift/cluster-kube-apiserver-operator) via a sed replacement. This is definitely prone to errors if something small changes in the future so as a debug step you should check the contents of this file on the bootstrap machine during cluster bootstrap.

## Replace existing bootkube.sh
Now that you've got a patched version of `bootkube.sh` you will need to re-encode it back to base64. Ignitiion does not support havign two conflicting paths within the same Ignition configuration so you will need to *replace* the original base64 string with your modified one. You can do this with an automated tool like `jq` or `yq` or by hand.