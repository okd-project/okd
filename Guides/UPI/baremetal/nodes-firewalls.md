Nodes with firewalls
---

If you have an interface which is accessible by the general interenet you may want to control what services are accessible by means of a firewall.

Due to the nature of K8s and how OKD deploys this is not as simple as you might expect.

You will need to interface with the contasiner network provider within your cluster to ensure that your configuration is applied correctly.

Regardless of your method of configuration, you should externally test and verify the reachable-ness of ports and services.

# It's not as simple as pushing iptables rules!

Initially, you may be tempted to deploy a MachineConfig to your nodes to manipulate iptables. Especially when using the default setup of Openshift SDN or OVNKubernetes.

The following may seem like a potential option:
- Resolve the public interface name
- Create an iptables chain for the public internet
- Filter input traffic flowing over the public interface into the namespace
- Reject forwarding traffic from the public interface
- Filter ports within chain to only allow certain services (e.g SSH, HTTPS, Node Port ranges)

You can create an iptables ruleset which does all this and it may work... tempoarily. For example, when deploying with OpenshiftSDN - whenever OpenshiftSDN needs to update it's iptables ruleset it updates it at index 0 - basically meaning it will be prepended before your rules - circumventing any filtering you are doing.

Unless you are integrating into the CNI manually - blindly configuring iptables will not go well for you.
