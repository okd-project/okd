Enable or Disable Network Interfaces
---
You may want to enable or disable network interfaces on a node. The network interface could be for IPMI which will never come up, or it could be that you have a physical adapter which is link-active but not required.

An misconfigured adapter can delay startup due to NetworkManager waiting for DHCP etc, and will also lead to the failure of the network-online service within systemd.

FCOS uses [NetworkManager](https://gitlab.freedesktop.org/NetworkManager/NetworkManager) to look after interfaces and network related configuration.

We will use MachineConfigs to deploy NetworkManager configuration to our nodes.

You can deploy these Machine Configs with a running cluster, or you can do this at cluster installation by including the yaml within the `manifests` folder after running `openshift-install create manifests` but prior to running `openshift-install create ignition-configs`.

## Disable an interface
We will "disable" an interface by telling NetworkManager to mark it as unmanaged.


This MachineConfig object will add the configuration file in the right place:
```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  # Customise the name to describe the network interface being disabled
  name: okd-configure-master-disable-XYZ-network-interface
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
        - contents:
            # See notes below on generating base64
            source: data:text/plain;charset=utf-8;base64,<YOUR_BASE64_HERE>
          mode: 420
          # Customise the name to describe the network interface being disabled
          path: /etc/NetworkManager/conf.d/50-disable-XYZ-interfaces.conf
```

If you are deploying into metal with identical setups (or close enough) you can rely on ["Predictable Network Interface Device Names"](https://cgit.freedesktop.org/systemd/systemd/tree/src/udev/udev-builtin-net_id.c#n20) to confidently effect the same interface across multiple nodes. 

This is an example configuration file to disable any interface starting with `enp0s`
```conf
[main]
plugins=keyfile

[keyfile]
unmanaged-devices=interface-name:enp0s*
```
Refer to the [NetworkManager.conf documentation](https://developer.gnome.org/NetworkManager/stable/NetworkManager.conf.html) to adapt to your specific requirements.

Once you have built a configuration to suit, encode this configuration into base64 and insert it into the MachineConfig.
