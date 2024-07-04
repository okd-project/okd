# Community Testing

## Releases

There are currently no new releases of OKD while we ramp up our build and testing process for OKD SCOS. You can [read more about this effort on the OKD website](https://www.okd.io/blog/2024/06/01/okd_future_statement/#okd-working-group-statement-june-1-2024)

**We currently only need testing of the OKD SCOS builds.** 

## Pre-release Builds 

Real world tests of the pre-release builds are a key component to the success of OKD. We encourage testing of all your desired use cases, and also these particular areas of focus:

* Samples Operator
* Any community operators
* Drivers
* Branding (Please keep any eye out for anything with Red Hat/OCP branding)

### Getting Started

Pre-release builds of OKD SCOS are currently available for [4.16](https://amd64.origin.releases.ci.openshift.org/#4.16.0-0.okd-scos) and [4.17](https://amd64.origin.releases.ci.openshift.org/#4.17.0-0.okd-scos). Please note that each pre-release build is pruned after 72 hours. If the build that you installed was pruned, the cluster may be unable to pull necessary images and may show errors for various functionality (including updates).

To pull a release, use an existing oc v4.x cli binary to pull the installer materials. You can find the latest release of the oc binary on the [OpenShfit client mirror page](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/).

```
oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:4.16.0-0.okd-scos-2024-06-26-093335
```
Extract the downloaded tarballs and copy the binaries into your PATH. Configure your environment for the desired platform. Perform an install appropriate for your needs. You can use the [OKD FCOS docs as a reference](https://docs.okd.io/4.16/welcome/index.html) 

For a cloud-based installation using installer provisioned resources, you can run...

 ```
 $ openshift-install create cluster
 ```

Depending on your configuration, you may be prompted for a pull-secret that will be made available to all of of your machines. For OKD4 you should either paste the pull-secret you use for your registry, or paste `{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}` to bypass the required value check (see [bug #182](https://github.com/openshift/okd/issues/182)).

Once the install completes successfully (usually 30m on AWS) the console URL and an admin username and password will be printed. If your DNS records were correct, you should be able to log in to your new OKD4 cluster!

For cloud-based installations, you can undo the installation and delete any cloud resources created by the installer by running..

```
$ openshift-install destroy cluster
```

### Submitting Testing Results

Please submit bugs and other testing result information to the [Pre-release Testing Discussion Category of the OKD repo](https://github.com/okd-project/okd/discussions/categories/pre-release-testing). Please use the labels "OKD SCOS 4.16" or "OKD SCOS 4.17" to help us categorize discussions further. Many thanks!
