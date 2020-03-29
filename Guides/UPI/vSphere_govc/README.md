# Install OKD 4 on top of an UPI VMware vSphere configuration
This guide explains how to provision Fedora CoreOS on vSphere and install OKD on it. The guide includes bash scripts to automate the govc command line tool for interacting with the vSphere cluster.

## Assumptions
- You have `openshift-installer` and `oc` for the OKD version you're installing in your PATH. See [Getting Started](/README.md#getting-started)
- This guide uses [govc](https://github.com/vmware/govmomi/tree/master/govc) to interface with vSphere. The examples assume you have already set up a connection with the required authenticated. You can complete the same tasks using a variety of tools, including PowerCLI, the vSphere web UI and terraform.
- The configuration uses `platform: none` which means that OKD will not integrate into vSphere and can not, for example, automatically provision volumes backed by vSphere datastores.
- You have a network / portgroup in vSphere you can use for the cluster.

## Walkthrough

### Obtain Fedora CoreOS images
Find and download an image of FCOS for VMware vSphere from https://getfedora.org/en/coreos/download/

```
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/31.20200113.3.1/x86_64/fedora-coreos-31.20200113.3.1-vmware.x86_64.ova 

# Import into vSphere
govc import.ova -ds=<datastore_name> \
    -name fedora-coreos-31.20200113.3.1-vmware.x86_64 \
    fedora-coreos-31.20200113.3.1-vmware.x86_64.ova
```

### Create FCOS VMs
```
#!/bin/bash
# Title: UPI-vSphere-GenerateVMs
# Description: This is an example bash script to create the VMs iteratively. Set the values for cluster_name, datastore_name, vm_folder, network_name, master_node_count, and worker_node_count.
 
template_name="fedora-coreos-31.20200113.3.1-vmware.x86_64"
cluster_name=<cluster_name>
datastore_name=<datastore_name>
vm_folder=<folder_path>
network_name=<network_name>
master_node_count=<master_node_count>
worker_node_count=<worker_node_count>

# Create the master nodes

for (( i=1; i<=${master_node_count}; i++ )); do
        vm="${cluster_name}-master-${i}"
	govc vm.clone -vm "${template_name}" \
		-ds "${datastore_name}" \
		-folder "${vm_folder}" \
		-on="false" \
		-c="4" -m="8192" \
		-net="${network_name}" \
		$vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G
done

# Create the worker nodes

for (( i=1; i<=${worker_node_count}; i++ )); do
        vm="${cluster_name}-worker-${i}"
        govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="4" -m="8192" \
                -net="${network_name}" \
                $vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G
done


# Create the bootstrap node

vm="${cluster_name}-bootstrap"
govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="4" -m="8192" \
                -net="${network_name}" \
                $vm
govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G


```

### Configure DNS, DHCP and LB
The installation requires specific configuration of DNS and a load balancer. The requirements are listed in the official Openshift documentation: [Creating the user-provisioned infrastructure](https://docs.okd.io/latest/installing/installing_vsphere/installing-vsphere.html#installation-infrastructure-user-infra_installing-vsphere). Example configurations are available at [requirements](/Guides/UPI/vSphere_govc/Requirements)

You will also need working DHCP on the network the cluster hosts are connected to. The DHCP server should assign the hosts unique FQDNs.

### Create cluster configuration and Ignition files
Create `install-config.yaml`:

```
apiVersion: v1
baseDomain: domain.tld
metadata:
  name: cluster

compute:
- hyperthreading: Enabled
  name: worker
  replicas: 3

controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3

platform:
  none: {}

pullSecret: '<Your pull secret from https://cloud.redhat.com/openshift/install/vsphere/user-provisioned>'
sshKey: <Your public SSH key beginning with ssh-rsa ...>
```

**NOTE**: It is a good idea to keep a copy of `install-config.yaml` for if you need to recreate the Ignition files since the following step destroys it.


Generate Ignition-configs:

```
openshift-install create ignition-configs
```

Your `install-config.yaml` file should have been replaced with a bunch of `.ign` files which will be used to configure the FCOS hosts. 

**NOTE**: If you want to totally regenerate the Ignition configs (for example to replace expired temporary certificates) you will also need to remove a hidden `.openshift_install_state.json`-file

### Serve bootstrap.ign

Due to the size of the bootstrap.ign file it can't be directly written into the VM metadata but needs to be served over HTTP instead. One way to do this is to use `python3 -m http.server`.

Create a file `append-bootstrap.ign` which contains an URL to the full `bootstrap.ign`:

```
{
  "ignition": {
    "config": {
      "merge": [
        {
          "source": "http://10.0.0.50:8000/bootstrap.ign", 
          "verification": {}
        }
      ]
    },
    "timeouts": {},
    "version": "3.0.0"
  }
}
```

### Set the VM metadata
Steps which need to be done:
- Set the VM property `guestinfo.ignition.config.data` to a base64-encoded version of the Ignition-config
- Set the VM property `guestinfo.ignition.config.data.encoding` to `base64`
- Set the VM property `disk.EnableUUID` to `TRUE`

```
#!/bin/bash
# Title: UPI-vSphere-AddMetadata
# Description: This is an example bash script to set the metadata on the VMs iteratively. Set the values for cluster_name, master_node_count, and worker_node_count.

cluster_name=<cluster_name>
master_node_count=<master_node_count>
worker_node_count=<worker_node_count>

# Set the metadata on the master nodes

for (( i=1; i<=${master_node_count}; i++ )); do
        vm="${cluster_name}-master-${i}"
	govc vm.change -vm $vm \
		-e guestinfo.ignition.config.data="$(cat master.ign | base64 -w0)" \
		-e guestinfo.ignition.config.data.encoding="base64" \
		-e disk.EnableUUID="TRUE"
done

# Set the metadata on the worker nodes

for (( i=1; i<=${worker_node_count}; i++ )); do
        vm="${cluster_name}-worker-${i}"
	govc vm.change -vm $vm \
                -e guestinfo.ignition.config.data="$(cat worker.ign | base64 -w0)" \
                -e guestinfo.ignition.config.data.encoding="base64" \
                -e disk.EnableUUID="TRUE"
done

# Set the metadata on the bootstrap node

vm="${cluster_name}-bootstrap"
govc vm.change -vm $vm \
	-e guestinfo.ignition.config.data="$(cat append-bootstrap.ign | base64 -w0)" \
	-e guestinfo.ignition.config.data.encoding="base64" \
	-e disk.EnableUUID="TRUE"

```

### Start the bootstrap server
After every server in your cluster was provisioned, start the bootstrap server.
By default, Fedora CoreOS will install the OS from the official OSTree image, so we have to wait a few minutes for the machine-config-daemon to pull and install the pivot image from the registry. This image is necessary for the kubelet service, as the official Fedora CoreOS image does not include hyperkube.
After the image was pulled and installed, the server will be rebooted by itself.
When the server is up again wait for the API service and the MachineConfig service to be spawned (check for the ports 6443 and 22623). Check also for the status of the `bootkube.service`.

### Start the other servers
**NOTE:** You can start every server in the cluster in the same time of the boostrap server, as they will still waiting for the latter to expose the Kubernetes and MachineConfig API ports. These steps were separated just for convenience.

Now that the bootstrap server is ready, you can start every server of your cluster.
Just like the bootstrap server, the control planes and the workers will boot with the official Fedora CoreOS image, that does not contains hyperkube. Since hyperkube is missing the kubelet service will not start and so the cluster bootstrapping.
Wait for the machine-config-daemon to pull the same image as the bootstrap server. The servers will reboot themselves and after that they will try to join the cluster, starting the bootstrapping process.

For debugging you can use `sudo crictl ps` and `sudo crictl logs <container_id>` to inspect the state of the various components.

### Install OKD cluster
#### Bootstrap stage
Now that every servers is up and running, they are ready to form the cluster.
Bootstrap will start as soon as the master nodes finish forming the etcd cluster.

Meanwhile just run the OKD Installer in order to check the status of the installation:

`$ openshift-installer wait-for bootstrap-complete --log-level debug`

The installer will now check for the availability of the Kubernetes API and then for the `bootstrap-complete` event that will be spawned after the cluster has almost finished to install every cluster operator.
OKD installer will wait for 30 minutes. It should be enough to complete the bootstrap process.

#### Intermediate stage
When the bootstrap is finished you have to approve the nodes CSR, configure the storage backend for the `image-registry` cluster operator, and shutting down the bootstrap node.

Shut down the bootstrap vm and then remove it from the pools of the load balancer. If you followed the [LB_HAProxy.md](../Requirements/LB_HAProxy.md) guide to configure HAProxy as you load balancer, just comment the two `bootstrap` records in the configuration file, and then restart its service.

After the bootstrap vm is offline, authenticate as `system:admin` in OKD, by using the `kubeconfig` file, which was created when Ingnition configs were [generated](#generate-the-ignition-configuration-files).

Export the `KUBECONFIG` variable like the following example:

`$ export KUBECONFIG=$(pwd)/auth/kubeconfig`

You should now bo able to interact with the OKD cluster by using the `oc` utility.

For the certificate requests, you can approve them with:

`$ oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve`.

For the `image-registry` cluster operator things are getting a bit more tricky.

By default registry would expect a storage provider to provide an RWX volume, or to be configured to be ephemeral.

If you want the registry to store your container images, follow the [official OKD 4 documentation](https://docs.okd.io/latest/registry/configuring-registry-storage/configuring-registry-storage-baremetal.html) to configure a persistent storage backend. There are many backend you can use, so just choose the more appropriate for your infrastructure.

If you want instead to use an ephemeral registry, just run the following command to use `emptyDir`:  
`$ oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'`

**NOTE:** While `emptyDir` is suitable for non-production or temporary cluster, it is not recommended for production environments.

#### Final stage
Now that everything is configured run the OKD installer again to wait for the `install-complete` event.

`$ openshift-install wait-for install-complete --log-level debug`

After the installation is complete you can login into your cluster via WebUI using `kubeadmin` as login. Password for this account is auto-generated and stored in `auth/kubeadmin-password` file. If you want to use the `oc` utility, you can still use the `kubeconfig` file you used [before](#intermediate-stage).

**NOTE:** `kubeadmin` is a temporary user and should not be left enabled after the cluster is up and running.
Follow the [official OKD 4 documentation](https://docs.okd.io/latest/authentication/understanding-authentication.html) to configure an alternative Identity Provider and to remove `kubeadmin`.
