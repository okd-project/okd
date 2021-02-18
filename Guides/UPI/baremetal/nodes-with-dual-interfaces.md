Nodes with dual interfaces
---

The generic K8s model is that nodes are on a secured private network and traffic is routed from a *magical* load balancer provided by, usually, a cloud provider or perhaps if you are deploying in your own datacentre - dedicated hardware which is managed outside your cluster. 

When deploying onto commodity bare metal servers from most mainstream providers, this is likely to not be the case. You are likely to have a single NIC which has a publically routable address or, perhaps, you have two NICs: one for public traffic and one for an internal network.

This document provides a few gotchas which you may come across and potential work arounds

# Send cluster traffic over the Private Network
When your node has a public interface and a private interface, you will, generally, want to have your cluster traffic going over the private network.

The Node's "InternalIP" is what other nodes use to resolve the IP of other nodes - not DNS. This means even if your DNS is configured to use private IPs, that does not mean that the other nodes will use that.

The default IP to use for "InternalIP" is, by default, determined by the [node-ip](https://github.com/openshift/baremetal-runtimecfg/blob/master/cmd/runtimecfg/node-ip.go) command. In a network scenario where eno1 is the public interface and eno2 is the private interface, this command will use the IP in the public interface by default.

In order to configure cluster-internal traffic to traverse over the private network you need to set the Kubelet IP manually.

Follow the guide in [Nodes with custom IP](nodes-custom-ip.md)

# Secure public interfaces
There is an inherent assumption that Nodes operate on a private and secured network in most k8s and OKD deployments. Although there is some security over the wire (e.g secured API calls with cluster certificates), certain exposed services (like the Openshift SDN VXLAN ports) probably don't want to be exposed to the public internet.

Inevitably, this is an important topic which will invariably differ from setup to setup. Depending on your setup you may be able to setup a firewall at your network edge, or you may need to setup firewalls on each node.

You will need to refer to the documentation of whatever CNI you are using (e.g OpenshiftSDN, OVNKubernetes, Calico, etc). Some CNI's may have 

You will also need an understanding of the workload of your cluster to understand what traffic needs to be allowed in from the outside world (e.g 443, node ports, kube api)

You may find the [push firewalls to nodes guide](nodes-firewalls.md) useful.
