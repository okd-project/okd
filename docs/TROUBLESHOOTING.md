# Troubleshooting OKD Clusters

Is your cluster failing to install or upgrade?
Think you found a bug in OKD?
Use the following guides to diagnose your cluster's issues.

## Troubleshoot Failed Installations

Refer to the openshift [installer troubleshooting guide](https://github.com/openshift/installer/blob/master/docs/user/troubleshooting.md)
for instructions on how to debug a failed installation.

## Troubleshoot Failed Upgrades

An upgrade will fail to complete if one or more operators do the following:

1. Do not report they are at the correct cluster version
2. Mark themselves as unavailable (`AVAILABLE=False`) or degraded (`DEGRADED=True`)

If the control plane remains available, you should be able to use the must-gather tool to extract
debugging information for each operator. To do so, run `oc adm must-gather` as the cluster
administrator. You can also follow the "General Troubleshooting Procedures" below.

## General Troubleshooting Procedures

### Step 0: Check Overall Health

Use the `ClusterVersion` instance to get a simple healthy/unhealthy status of your cluster:

```bash
$ oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.3.0     True        False         31m     Cluster version is 4.3.0
```

If `PROGRESSING=True`, it means that your cluster is in the process of installing or upgrading
itself. Review the `STATUS` message to see which operators are unhealthy or are in the process
of rolling out their own installs/upgrades.

If you cannot see the `ClusterVersion` object, it means that one or more of the api servers pods
are down, and you will need to take more drastic measures to debug your cluster.

### Step 1: Find Unhealthy Operators

Each core OKD component has an operator which manages its installation and reports its current
status. The status of each component can be obtained by listing all `ClusterOperator` objects:

```bash
$ oc get clusteroperators
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.3.0     True        False         False      32m
cloud-credential                           4.3.0     True        False         False      53m
cluster-autoscaler                         4.3.0     True        False         False      42m
console                                    4.3.0     True        False         False      38m
dns                                        4.3.0     True        False         False      46m
image-registry                             4.3.0     False       False         True       42m
ingress                                    4.3.0     True        False         False      41m
insights                                   4.3.0     True        False         False      48m
kube-apiserver                             4.3.0     True        False         False      45m
kube-controller-manager                    4.3.0     True        False         False      45m
kube-scheduler                             4.3.0     True        False         False      45m
machine-api                                4.3.0     True        False         False      47m
machine-config                             4.3.0     True        False         False      43m
marketplace                                4.3.0     True        False         False      43m
monitoring                                 4.3.0     True        False         False      40m
network                                    4.3.0     True        False         False      48m
node-tuning                                4.3.0     True        False         False      44m
openshift-apiserver                        4.3.0     True        False         False      44m
openshift-controller-manager               4.3.0     True        False         False      46m
openshift-samples                          4.3.0     True        False         False      42m
operator-lifecycle-manager                 4.3.0     True        False         False      47m
operator-lifecycle-manager-catalog         4.3.0     True        False         False      47m
operator-lifecycle-manager-packageserver   4.3.0     True        False         False      45m
service-ca                                 4.3.0     True        False         False      48m
service-catalog-apiserver                  4.3.0     True        False         False      44m
service-catalog-controller-manager         4.3.0     True        False         False      44m
storage                                    4.3.0     True        False         False      43m
support                                    4.3.0     True        False         False      48m
```

Operators which report `PROGRESSING=True` indicate that changes to the managed component are in the
process of being rolled out. These changes can be new versions of component (in an upgrade), or
changes applied to the component's desired configuration.

Operators which report `DEGRADED=True` indicate that the managed component is operating at reduced
level of service than what is desired. This does not mean that the component is out of service -
however, degraded operators trigger an alert and generally require administrator intervention to
resolve.

Operators which report `AVAILABLE=False` indicate that the managed component is not operational.
This means that one or more critical features of OKD will not work as desired. Operators which are
not available will trigger an alert and generally require administrator intervention to resolve.

If an operator is reporting `AVAILABLE=False` or `DEGRADED=True`, the cluster cannot be
automatically upgraded.

### Step 2: Identify Reason Operator Is Unhealthy

```bash
$ oc get clusteroperator image-registry -o yaml
apiVersion: config.openshift.io/v1
kind: ClusterOperator
metadata:
  creationTimestamp: "2019-12-05T15:45:19Z"
  generation: 1
  name: image-registry
  resourceVersion: "28663"
  selfLink: /apis/config.openshift.io/v1/clusteroperators/image-registry
  uid: <uuid>
spec: {}
status:
  conditions:
  - lastTransitionTime: "2019-12-05T15:46:54Z"
    message: The registry is ready
    reason: Ready
    status: "True"
    type: Available
  - lastTransitionTime: "2019-12-05T16:35:58Z"
    message: The registry is ready
    reason: Ready
    status: "False"
    type: Progressing
  - lastTransitionTime: "2019-12-05T15:45:27Z"
    status: "False"
    type: Degraded
  extension: null
  relatedObjects:
  - group: imageregistry.operator.openshift.io
    name: cluster
    resource: configs
  - group: ""
    name: openshift-image-registry
    resource: namespaces
  ...
  versions:
  - name: operator
    version: 4.3.0
```

### Step 3: Debug The Operator

#### Extract Data with Must-Gather

```bash
$ oc adm must-gather
[must-gather      ] OUT Using must-gather plugin-in image: <release-image>
[must-gather      ] OUT namespace/openshift-must-gather-n5285 created
[must-gather      ] OUT clusterrolebinding.rbac.authorization.k8s.io/must-gather-8dlhk created
[must-gather      ] OUT pod for plug-in image <release-image> created
[must-gather-w4fd7] POD Wrote inspect data to must-gather.
[must-gather-w4fd7] POD Gathering data for ns/openshift-cluster-version...
[must-gather-w4fd7] POD Wrote inspect data to must-gather.
[must-gather-w4fd7] POD Gathering data for ns/openshift-config...
[must-gather-w4fd7] POD Gathering data for ns/openshift-config-managed...
[must-gather-w4fd7] POD Gathering data for ns/openshift-authentication...
[must-gather-w4fd7] POD Gathering data for ns/openshift-authentication-operator...
[must-gather-w4fd7] POD Gathering data for ns/openshift-ingress...
...
```

#### Debug the Operator
