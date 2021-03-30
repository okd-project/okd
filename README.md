OKD: The Community Distribution of Kubernetes that powers Red Hat's OpenShift
=============================================================================

<img src="./img/okd-panda-flat_rocketeer_with_number.svg" height="200">

[![Licensed under Apache License version 2.0](https://img.shields.io/github/license/openshift/origin.svg?maxAge=2592000)](https://www.apache.org/licenses/LICENSE-2.0)

***OKD*** is the community distribution of [Kubernetes](https://kubernetes.io) optimized for continuous application development and multi-tenant deployment. OKD adds developer and operations-centric tools on top of Kubernetes to enable rapid application development, easy deployment and scaling, and long-term lifecycle maintenance for small and large teams. ***OKD*** is also referred to as ***Origin*** in github and in the documentation.  ***OKD*** makes launching Kubernetes on any cloud or bare metal a snap, simplifies running and updating clusters, and provides all of the tools to make your containerized-applications succeed.

This repository covers OKD4 and newer. For older versions of OKD, see the [3.11 branch of openshift/origin](https://github.com/openshift/origin/tree/release-3.11).

The [OKD Working Group](https://github.com/openshift/community#okd-working-group-meetings) meets bi-weekly to discuss development and next steps.  Meeting schedule and location are tracked in the [openshift/community repo](https://github.com/openshift/community/projects/1#card-28309038).


Getting Started
---------------

To obtain the openshift installer and client, visit [/releases](https://github.com/openshift/okd/releases) for stable versions or [https://origin-release.svc.ci.openshift.org/](https://origin-release.svc.ci.openshift.org/) for nightlies. See [a list of public keys](https://okd.io/keys.html) to verify tools signature. Please note that each nightly release is pruned after 72 hours. If the nightly that you installed was pruned, the cluster may be unable to pull necessary images and may show errors for various functionality (including updates).
Alternatively, if you have the openshift client `oc` already installed, you can use it to download and extract the openshift installer and client from our container image:

```
$ oc adm release extract --tools quay.io/openshift/okd:4.5.0-0.okd-2020-07-14-153706-ga
```

**NOTE**: You need a 4.x version of `oc` to extract the installer and the latest client. You can initially use the [official Openshift client (mirror)](https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/)

Extract the downloaded tarballs and copy the binaries into your PATH. Then run the following from an empty directory:

```
$ openshift-install create cluster
```

You'll be prompted to choose a platform to install to - AWS is currently the best place to start with OKD4 while we get Fedora CoreOS machine images set up in the other clouds.

You will need to have cloud credentials set in your shell properly before installation. You must have permission to configure the appropriate cloud resources from that account (such as VPCs, instances, and DNS records). You must have already configured a public DNS zone on your chosen cloud before the install starts.

You will also be prompted for a pull-secret that will be made available to all of of your machines - for OKD4 you should either paste the pull-secret you use for your registry, or paste `{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}` to bypass the required value check (see [bug #182](https://github.com/openshift/okd/issues/182)).

Once the install completes successfully (usually 30m on AWS) the console URL and an admin username and password will be printed. If your DNS records were correct, you should be able to log in to your new OKD4 cluster!

To undo the installation and delete any cloud resources created by the installer, run

```
$ openshift-install destroy cluster
```

[Learn more about the installer](https://github.com/openshift/installer/blob/master/docs/user/overview.md)

The OpenShift client tools for your cluster can be downloaded from the web console.


Features
--------

* A fully automated distribution of Kubernetes on all major clouds and bare metal, OpenStack, and other virtualization providers
  * Easily build applications with integrated service discovery and persistent storage.
  * Quickly and easily scale applications to handle periods of increased demand.
    * Support for automatic high availability, load balancing, health checking, and failover.
  * Access to the Operator Hub for extending Kubernetes with new, automated lifecycle capabilities
* Developer centric tooling and console for building containerized applications on Kubernetes
  * Push source code to your Git repository and automatically deploy containerized applications.
  * Web console and command-line client for building and monitoring applications.
* Centralized administration and management of an entire stack, team, or organization.
  * Create reusable templates for components of your system, and iteratively deploy them over time.
  * Roll out modifications to software stacks to your entire organization in a controlled fashion.
  * Integration with your existing authentication mechanisms, including LDAP, Active Directory, and public OAuth providers such as GitHub.
* Multi-tenancy support, including team and user isolation of containers, builds, and network communication.
  * Allow developers to run containers securely with fine-grained controls in production.
  * Limit, track, and manage the developers and teams on the platform.
* Integrated container image registry, automatic edge load balancing, and full spectrum monitoring with Prometheus.

Learn More
----------

* **[Public Documentation](https://docs.okd.io/latest/welcome/)**

For questions or feedback, reach us on [Kubernetes Slack on #openshift-dev](https://kubernetes.slack.com/) or post to our [mailing list](https://lists.openshift.redhat.com/openshiftmm/listinfo/dev).


### What can I run on OKD?

OKD is designed to run any Kubernetes workload. It also assists in building and developing containerized applications through the developer console.

For an easier experience running your source code, [Source-to-Image (S2I)](https://github.com/openshift/source-to-image) allows developers to simply provide an application source repository containing code to build and run.  It works by combining an existing S2I-enabled container image with application source to produce a new runnable image for your application.

You can see the [full list of Source-to-Image builder images](https://github.com/openshift/library/tree/master/official) and it's straightforward to [create your own](https://blog.openshift.com/create-s2i-builder-image/).  Some of our available images include:

  * [Ruby](https://github.com/sclorg/s2i-ruby-container)
  * [Python](https://github.com/sclorg/s2i-python-container)
  * [Node.js](https://github.com/sclorg/s2i-nodejs-container)
  * [PHP](https://github.com/sclorg/s2i-php-container)
  * [Perl](https://github.com/sclorg/s2i-perl-container)
  * [WildFly](https://github.com/openshift-s2i/s2i-wildfly)
  * [MySQL](https://github.com/sclorg/mysql-container)
  * [MongoDB](https://github.com/sclorg/mongodb-container)
  * [PostgreSQL](https://github.com/sclorg/postgresql-container)
  * [MariaDB](https://github.com/sclorg/mariadb-container)

### What sorts of security controls does OpenShift provide for containers?

OKD runs with the following security policy by default:

  * Containers run as a non-root unique user that is separate from other system users
    * They cannot access host resources, run privileged, or become root
    * They are given CPU and memory limits defined by the system administrator
    * Any persistent storage they access will be under a unique SELinux label, which prevents others from seeing their content
    * These settings are per project, so containers in different projects cannot see each other by default
  * Regular users can run Docker, source, and custom builds
    * By default, Docker builds can (and often do) run as root. You can control who can create Docker builds through the `builds/docker` and `builds/custom` policy resource.
  * Regular users and project admins cannot change their security quotas.

Many containers expect to run as root (and therefore edit all the contents of the filesystem). The [Image Author's guide](https://docs.okd.io/latest/openshift_images/create-images.html#images-create-guide-openshift_create-images) gives recommendations on making your image more secure by default:

* Don't run as root
* Make directories you want to write to group-writable and owned by group id 0
* Set the net-bind capability on your executables if they need to bind to ports < 1024

If you are running your own cluster and want to run a container as root, you can grant that permission to the containers in your current project with the following command:

    # Gives the default service account in the current project access to run as UID 0 (root)
    oc adm add-scc-to-user anyuid -z default

See the [security documentation](https://docs.okd.io/latest/authentication/managing-security-context-constraints.html) more on confining applications.


Contributing
------------

OKD is built from many different open source projects - Fedora CoreOS, the CentOS and UBI RPM ecosystems, cri-o, Kubernetes, and many different extensions to Kubernetes. The `openshift` organization on GitHub holds active development of components on top of Kubernetes and references projects built elsewhere. Generally, you'll want to find the component that interests you and review their README.md for the processes for contributing.

Community process and questions can be raised in our [community repo](https://github.com/openshift/community) and issues [opened in this repository](https://github.com/openshift/okd/issues) (Bugzilla locations coming soon).

Our unified continuous integration system tests pull requests to the ecosystem and core images, then builds and promotes them after merge. To see the latest development releases of OKD visit [our continuous release page](https://origin-release.svc.ci.openshift.org). These releases are built continuously and expire after a few days. Long lived versions are pinned and then listed on our [stable release page](https://github.com/openshift/okd/releases).

All contributions are welcome - OKD uses the Apache 2 license and does not require any contributor agreement to submit patches.  Please open issues for any bugs or problems you encounter, ask questions on the OpenShift IRC channel (#openshift-dev on freenode), or get involved in the [Kubernetes project](https://github.com/kubernetes/kubernetes) at the container runtime layer.

See [Contributing Guide](./CONTRIBUTING.md) for more technical examples.

Security Response
-----------------
If you've found a security issue that you'd like to disclose confidentially
please contact Red Hat's Product Security team. Details at
https://access.redhat.com/security/team/contact


Frequently asked questions
--------------------------
We collect frequently asked questions and their answers on this page:
[Frequently Asked Questions](./FAQ.md)


Known Issues
--------------------------
Known issues and possible workarounds are documented on this page:
[Known Issues](./KNOWN_ISSUES.md)

License
-------

OKD is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/). Some components may be licensed differently - consult individual repositories for more.
