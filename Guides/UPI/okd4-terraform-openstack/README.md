# Openshift community OKD4 (UPI) on Openstack with terraform

Terraform code to provision OKD4 using user provisioned installer (UPI) and
glue code to tie it all together

From an openshift installer perspective this is a "bare metal" install:
https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installing-bare-metal
User provided infrastructure is orchestrated using terraform in combination with scripts and an ansible playbook.

Tested on Openstack RDO with Calico as SDN in Openstack and openstack designate
for DNS setup within terraform (specifically https://nrec.no/)

Disclaimer: This code is for testing / proof-of-concept and not for production use.

NB: You don't want to be logged in to other openshift cluster contexts when
running this deployment. It might take you in an unexpected direction :-)

## How to use

First clone this repo to local host and `cd Guides/UPI/okd4-terraform-openstack`

There is two scripts, `update-installer-and-image.sh` and
`deploy.sh`, for getting dependencies and deploying the
cluster respectively.

You need access to an openstack project with enoght resources to accomodate nodes according to
https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#minimum-resource-requirements_installing-bare-metal , a DNS subdomain that can be controlled with the Openstack API. Also, this terraform
code assumes that instances automatically get a NIC with public IPv4
address assigned to it.

### Preparing the environment

Find out which version of Fedora CoreOS and openshift installer you want to use
for the deployment. You probably want to fetch them from the "Name" and
"Component Versions: (machine-os)" section of an OKD-release on
https://github.com/openshift/okd/releases.

In order to use the update-installer-and-image.sh you must first be
authenticated to the openstack project (in order to upload the FCOS image).

Then you can for example do:

`./scripts/update-installer-and-image.sh 4.4.0-0.okd-2020-04-21-163702-beta4 31.20200420.20`

It is of course also possible to combine any version of FCOS and OKD and/or
download directly from the realease pages of OKD and Fedora CoreOS and manually
do what the script does with any combination of OKD build and Fedora CoreOS
build. Just be aware that the image dependencies used by an nightly build may or
may not be available on quay.io.

Ref:

* https://builds.coreos.fedoraproject.org/browser
* https://origin-release.svc.ci.openshift.org/

## Configuring the deployment

First edit the `terraform.tfvars` file and fill in according to the comments.

PS: The load balancer uses a standard Centos 7 image that must be present in
the Openstack project. The default name is found in the `variables.tf` but can
be overridden in terraform.tfvars (as all other default variable values) to
what the name of the image is in your project.   

Then edit the install-config.yaml and put in the parameters according to comments.

## Deploying the cluster

In addition to the previous requirements you also need access to a s3 bucket in
order to store the ignition config for the bootstrap node which is so huge that it
will grow the user_data field inside the POST request to openstack so much that
creating the boot instance fails due to exeeded size limit in the Openstack
API.

The `deploy.sh` script takes two arguments: `install-config.yaml` and
`s3-endpoint-url` of the s3 object store to first put and subsequently fetch
the ignition config of the bootstrap node.

You must have the `aws` cli installed and configured with credentials and
privileges to to put and presign the ignition file to the s3-ignition-url.

When it is in place you can run the deploy script:

`scripts/deploy.sh`

The first thing that happens is that it creates manifests that unfortunately
have to be modified before further processing. So the script stops and asks you
to edit `installer/manifests/cluster-scheduler-02-config.yml` (which was just
created). Change `mastersSchedulable: true` to `mastersSchedulable: False`. Then
hit return to continue.

The script will frist run terraform with paramaters that override default
values in `terraform.tfvars` in order to start out only with 3 control plane
nodes and one bootstrap node. When bootstrap is complete terraform desired
state is applied with default values (which means 0 boot nodes and N worker
nodes. Loadbalancer (haproxy) config are applied and updated several times  in
between in order to reflect the changes in the set of nodes during bootstrap.

During the bootstrap you can follow the progress of cluster operators with:

```
export KUBECONFIG=installer/auth/kubeconfig
watch ./oc get co
```

Finally csr's of worker nodes are approved, (or actually all pending csr's are
approved, assuming it is the nodes that requested them, Be aware)

To get login information when cluster is completely installed:

`./openshift-install --dir=installer/ wait-for install-complete`

Please see the `deploy.sh` script for next steps and details on what's going on

To tear everything down:

`terraform destroy`
