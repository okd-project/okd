# Install OKD 4 on top of an UPI libvirt+kvm configuration

This guide explains how to configure libvirt+KVM to provision Fedora CoreOS and install OKD on top of it.

## Assumptions
- The host OS is CentOS 7;
- This guide will not configure the load balancer or the DNS server. Check for Requirements/LB_HAProxy.md and Requirements/DNS_Bind.md if you want to configure them;
- Fedora CoreOS will still use DHCP for obtaining the IP, but with a MAC address-based reservation into the libvirt network configuration. So there is no need for a standalone DHCP server.
- You already downloaded the OKD installer and command line tools from the Release section of this repository, and installed them into a path added to the `PATH` environment variable.


## Pre-tasks
1. Download from Fedora CoreOS website:
    - Installer ISO
    - Kernel
    - Initramfs
    - Raw image

    Despite we're not installing Fedora CoreOS from PXE, we still need to download the kernel and the initramfs, as we're going to use the Direct Kernel Boot feature of libvirt to inject kernel boot parameters.

2. Configure a webserver
    Configure a simple webserver to host the ignition configs and the raw image. These files will be downloaded by the CoreOS installer and deployed to the VMs.


## Walkthrough

### Configure libvirt network
Create a simple NAT network. Even the "default" network created by libvirt is fine.
 
There's no need to specify the IP reservation at this point, since the VMs don't exist yet. You can add the records in the dhcp block later.
 Just remember to stop and start the network after adding them.
```
<network connections='3'>
  <name>openshift</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='GATEWAY' netmask='NETMASK'>
    <dhcp>
      <range start='DHCP START IP RANGE' end='DHCP END IP RANGE'/>
      <--- Add the following lines after you'll get the MAC address of your VMs
      <host mac='BOOTSTRAP MAC ADDRESS' name='okd4bs' ip='BOOTSTRAP IP'/>
      <host mac='MASTER 0 MAC ADDRESS' name='okd4m0' ip='MASTER 0 IP'/>
      <host mac='MASTER 1 MAC ADDRESS' name='okd4m1' ip='MASTER 1 IP'/>
      <host mac='MASTER 2 MAC ADDRESS' name='okd4m2' ip='MASTER 2 IP'/>
      <host mac='WORKER 0 MAC ADDRESS' name='okd4w0' ip='WORKER 1 IP'/>
      <host mac='WORKER 1 MAC ADDRESS' name='okd4w1' ip='WORKER 2 IP'/>
      --->
    </dhcp>
  </ip>
</network>
```

### Create the install-config.yaml
Login to [Red Hat Cluster Manager](https://cloud.redhat.com/openshift/install) portal and obtain a pull secret. I chose Bare Metal as UPI provider.

Create a SSH key pair for SSH login to the cluster VMs, and then create your install-config.yaml, like the following example:
```
---
apiVersion: v1
baseDomain: YOUR_DOMAIN
compute:
- hyperthreading: Enabled   
  name: worker
  replicas: 0 
controlPlane:
  hyperthreading: Enabled   
  name: master 
  replicas: 3 
metadata:
  name: CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.100.0.0/14 
    hostPrefix: 23 
  networkType: OpenShiftSDN
  serviceNetwork: 
  - 172.30.0.0/16
platform:
  none: {} 
pullSecret: 'SECRET FROM RED HAT CLUSTER MANAGER'
sshKey: 'YOUR SSH PUBLIC KEY' 
```

Modify it accordingly to the size and the configuration of your cluster and then remember to backup it, because the OpenShift Installer will remove it after generating the Ignition configuration files.


### Generate the Ignition configuration files
```
$ openshift-install create ignition-configs
```

### Provision the VMs
A simple high-available OKD cluster would include 3 control planes and 2 workers. So for such configuration you need for 5 VMs + 1 for boostrapping.
Configure the VM for booting them with the kernel and initramfs you previously downloaded, with the following parameters:
- KERNEL: `/path/of/fedora-coreos-31.20191217.2.0-installer-kernel-x86_64`;
- INITRAMFS: `/path/of/fedora-coreos-31.20191217.2.0-installer-initramfs.x86_64.img`;
- BOOT ARGS: `ip=dhcp rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://WEB_SERVER_IP:PORT/fedora-coreos-31.20191217.2.0-metal.x86_64.raw.xz coreos.inst.ignition_url=http://WEB_SERVER_IP:PORT/SERVER_ROLE.ign`.
Replace `SERVER_ROLE` with `bootstrap` for the bootstrap server, with `master` for control plane servers, and with `worker` for worker servers.
Replace `WEB_SERVER_IP:PORT` with the endpoint of the webserver you previously configured.

Here how you can set such configuration in `virt-manager`:


**NOTE:** CoreOS installer automatically reboot the server after installation, so when the installation of Fedora CoreOS is finished shut down the VMs, otherwise the installer will keep installing the OS.

At this point you can add the VMs MAC address to the network configuration in libvirt, just like the example in the step 1 (the commented lines).

After the installation disable the Kernel boot arguments, as we don't need them anymore.


### Start the bootstrap server
After every server in your cluster was provisioned, start the bootstrap server.
By default, Fedora CoreOS will install the OS from the official OSTree image, so we have to wait a few minutes for the machine-config-daemon to pull and install the pivot image from quay.io. This image is necessary for the kubelet service, as the official Fedora CoreOS image does not include hyperkube.
After the image was pulled and installed, the server will be rebooted by itself.
When the server is up again wait for the API service and the MachineConfig service to be spawned (check for the ports 6443 and 22623). Check also for the status of the `bootkube.service`.

### Start the other servers
**NOTE:** You can start every server in the cluster in the same time of the boostrap server, as they will still waiting for the latter to expose the Kubernetes and MachineConfig API ports. These steps were separated just for convenience.

Now that the bootstrap server is ready, you can start every server of your cluster.
Just like the bootstrap server, the control planes and the workers will boot with the official Fedora CoreOS image, that does not contains hyperkube, so the kubelet service will not start and therefore the cluster bootstrapping won't start.
Wait for the machine-config-daemon to pull the same image as the bootstrap server.
The servers will reboot themselves and after that they will try to join the cluster.
After reboot `rpm-ostree status` should show something like:
```
[core@okd4m0 ~]$ rpm-ostree status
State: idle
AutomaticUpdates: disabled
Deployments:
● pivot://quay.io/openshift/okd-content@sha256:830ede6ea29c7b3e227261e4b2f098cbe2c98a344b2b54f3f05bb011e56b0209
              CustomOrigin: Managed by machine-config-operator
                 Timestamp: 2019-11-15T18:25:12Z

  ostree://fedora:fedora/x86_64/coreos/testing
                   Version: 31.20191217.2.0 (2019-12-18T14:11:27Z)
                    Commit: fd3a3a1549de2bb9031f0767d10d2302c178dec09203a1db146e0ad28f38c498
              GPGSignature: Valid signature by 7D22D5867F2A4236474BF7B850CB390B3C3359C4
```


Wait for the finish of the installation and then login to the console with the kubeadmin credentials, or configure an additional identity provider.

