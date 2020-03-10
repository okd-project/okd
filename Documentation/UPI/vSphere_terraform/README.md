# vSphere UPI

This guide explains how to provision Fedora CoreOS on vSphere and install OKD on it. It provides terraform files to create and destroy a cluster. This terraform files are based on the [CI-platform files](https://github.com/openshift/installer/tree/fcos/upi/vsphere), but are much simpler and doesn't include communication with other infrastructure components except vSphere.

## Pre-Requisites

* terraform > v0.12

## Prepare environment

Checkout the official [Openshift 4.3 Documentation](https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html#installation-requirements-user-infra_installing-vsphere). Add DNS and DHCP records for your virtual machines, that will be provisioned in next steps.

Install a loadbalancer in front of your API servers. Choose a high availability setup, if you need it. The loadbalancer is only for API traffic and Kubernetes can handle an outage of the API. During an outage the cluster is not able to change something.

Find, download and upload an image of FCOS for [VMware vSphere](https://getfedora.org/en/coreos/download/).

### Example Environment

This example environment includes three master and worker nodes. Etcd is running on master nodes.

Take a look into [Configure Bind/named for DNS service](../Requirements/DNS_Bind.md), if you need help to configure your DNS.

#### A-records with mac address

| FQDN | A-record | MAC address |
|------|----------|-------------|
| bootstrap.okd.example.com | 10.20.15.3 | 00:1c:14:00:00:03 |
| lb.okd.example.com | 10.20.15.2 | 00:1c:14:00:00:02 |
| api.okd.example.com | 10.20.15.2 | |
| api-int.okd.example.com | 10.20.15.2 | |
| master1.okd.example.com | 10.20.15.11 | 00:1c:14:00:00:11 |
| master2.okd.example.com | 10.20.15.12 | 00:1c:14:00:00:12 |
| master3.okd.example.com | 10.20.15.13 | 00:1c:14:00:00:13 |
| etcd-0.okd.example.com | 10.20.15.11 | |
| etcd-1.okd.example.com | 10.20.15.12 | |
| etcd-2.okd.example.com | 10.20.15.13 | |
| worker1.okd.example.com | 10.20.15.41 | 00:1c:14:00:00:41 |
| worker2.okd.example.com | 10.20.15.42 | 00:1c:14:00:00:42 |
| worker3.okd.example.com | 10.20.15.43 | 00:1c:14:00:00:43 |

#### SRV-records

| domain | TTL | priority | weight | port | target |
|--------|-----|----------|--------|------|--------|
| _etcd-server-ssl._tcp.okd.example.com | 86400 | 0 | 10 | 2380 (etcd) | 10.20.15.11, 10.20.15.12, 10.20.15.13

#### wildcard DNS record

| domain | A-record | comment |
|--------|----------|---------|
| *.apps.okd.example.com | 10.20.15.41, 10.20.15.42, 10.20.15.43 | For high availability, we choose the first three worker nodes, which should run the router component |

#### Loadbalancer - HAProxy configuration

Note: Binding the API port also to 443 allows us to connect easily with `oc`, no need for port number, e.g. `oc login api.okd.example.com`

```HAProxy
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    stats socket /var/lib/haproxy/stats

    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    timeout connect         10s
    timeout client          1m
    timeout server          1m

listen  stats
    bind *:9000
    mode            http
    log             global
    stats enable
    stats refresh 30s
    stats show-node

frontend openshift-api-server
    bind *:6443
    bind *:443
    default_backend openshift-api-server
    mode tcp
    option tcplog

backend openshift-api-server
    balance source
    mode tcp
    server btstrap 10.20.15.3:6443 check
    server master1 10.20.15.11:6443 check
    server master2 10.20.15.12:6443 check
    server master3 10.20.15.13:6443 check

frontend machine-config-server
    bind *:22623
    default_backend machine-config-server
    mode tcp
    option tcplog

backend machine-config-server
    balance source
    mode tcp
    server btstrap 10.20.15.3:22623 check
    server master1 10.20.15.11:22623 check
    server master2 10.20.15.12:22623 check
    server master3 10.20.15.13:22623 check
```

## Get openshift-install

Download oc from  <https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/>

Choose a release ([dev-releases](https://origin-release.svc.ci.openshift.org/), ...)

Extract `openshift-install` tool (e.g. `oc adm release extract --command=openshift-install registry.svc.ci.openshift.org/origin/release:4.4.0-0.okd-2020-02-28-084836`)

## Build a Cluster

1. Create an `install-config.yaml` in an empty folder.

   ```yaml
   apiVersion: v1
   baseDomain: YOUR_BASE_DOMAIN
   compute:
   - name: worker
     replicas: 3
   controlPlane:
     name: master
     replicas: 3
   metadata:
     name: YOUR_CLUSTER_ID
   networking:
     clusterNetworks:
     - cidr: 10.128.0.0/14
       hostPrefix: 23
     networkType: OpenShiftSDN
     serviceNetwork:
     - 172.30.0.0/16
   platform:
     vsphere:
       vcenter: 'vcenterocp.example.com'
       username: 'YOUR_VSPHERE_USER'
       password: 'YOUR_VSPHERE_PASSWORD'
       datacenter: 'OCP-Datacenter'
       defaultDatastore: 'iscsi-hdd'
   pullSecret: '{"auths":{"fake":{"auth": "bar"}}}'
   sshKey: 'YOUR_SSH_KEY'
   ```

1. Run `openshift-install create ignition-configs`.
   * This command consumes your `install-config.yaml`. Therefore, it's maybe worthwhile to make a copy of this file, before calling this command.

1. Fill out a terraform.tfvars file with the ignition configs generated. There is an example terraform.tfvars file in this directory named terraform.tfvars.example.
    * cluster_id
    * cluster_domain
    * base_domain
    * vsphere_server
    * vsphere_user
    * vsphere_password
    * vsphere_cluster
    * vsphere_datacenter
    * vsphere_datastore
    * vm_template
    * vm_network
    * control_plane_count
    * compute_count
    * bootstrap_ignition
    * control_plane_ignition
    * compute_ignition
    * bootstrap_mac
    * control_plane_macs
    * compute_macs

1. Copy `bootstrap.ign` to an accessible webserver. The bootstrap ignition config must be placed in a location that will be accessible by the bootstrap machine. For example, you could store the bootstrap ignition config in a gist.

1. Run `terraform init`.

1. Run `terraform apply -auto-approve`.

1. Run `openshift-install wait-for bootstrap-complete`. Wait for the bootstrapping to complete.

1. Run `terraform apply -auto-approve -var 'bootstrap_complete=true'`.
This will destroy the bootstrap VM.

1. Run `openshift-install wait-for install-complete`. Wait for the cluster install to finish.

1. Enjoy your new OpenShift cluster.

## Remove/Destroy a cluster

1. Run `terraform destroy -auto-approve`.

1. Remove all files, created by last installation (e.g `*.ign`, `metadata.json`, auth-folder, `.openshift_install*`)
