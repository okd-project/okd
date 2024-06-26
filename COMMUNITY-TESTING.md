# Community Testing

## Releases

There are currently no new releases of OKD while we ramp up our build and testing process for OKD SCOS. You can [read more about this effort on the OKD website](https://www.okd.io/blog/2024/06/01/okd_future_statement/#okd-working-group-statement-june-1-2024)



## Nightly Builds 

Real world tests of the nightly builds are a key component to the success of OKD. We encourage testing of all your desired use cases, and also these particular areas of focus:

* Samples Operator
* Any community operators
* Drivers
* Branding (Please keep any eye out for anything with Red Hat/OCP branding)

### Getting Started

Nightly builds of OKD SCOS are currently available for [4.16](https://amd64.origin.releases.ci.openshift.org/#4.16.0-0.okd-scos) and [4.17](https://amd64.origin.releases.ci.openshift.org/#4.17.0-0.okd-scos). Please note that each nightly release is pruned after 72 hours. If the nightly that you installed was pruned, the cluster may be unable to pull necessary images and may show errors for various functionality (including updates).

To pull a release, use an existing oc v4.x cli binary to pull the installer materials. You can find the latest release of the oc binary on the [OpenShfit client mirror page](https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/).

```
oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:4.16.0-0.okd-scos-2024-06-26-093335
```
Extract the downloaded tarballs and copy the binaries into your PATH. Then run the following from an empty directory:

```
$ openshift-install create cluster
```

Configure your environment for the desired platform. 

You will also be prompted for a pull-secret that will be made available to all of of your machines - for OKD4 you should either paste the pull-secret you use for your registry, or paste `{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}` to bypass the required value check (see [bug #182](https://github.com/openshift/okd/issues/182)).

Once the install completes successfully (usually 30m on AWS) the console URL and an admin username and password will be printed. If your DNS records were correct, you should be able to log in to your new OKD4 cluster!

To undo the installation and delete any cloud resources created by the installer, run

```
$ openshift-install destroy cluster
```

[Learn more about the installer](https://github.com/openshift/installer/blob/master/docs/user/overview.md)

The OpenShift client tools for your cluster can be downloaded from the web console.
