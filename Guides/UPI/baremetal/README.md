Bare Metal UPI - Tips & Tricks
===

These guides are designed to complement the [official installation documentation](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html).

Document | Overview
-------- | --------
[Installer Workspace](installer-workspace.md) | When doing bare metal deploys you may be doing a lot of them whilst having to tweak config files, manifests and more. This document contains a few tips and tricks on workspace layout.
[Manual DNS Configuration and Fix Fedora CoreOS (FCOS) resolv bug](manual-dns-and-fcos-dns-fix.md) | FCOS 33 contains a bug which breaks DNS during a fresh bare metal deploy. This document also explains how to inject custom DNS configuration into your deploy.
[Disable or Enable certain Network Interfaces](enable-disable-network-interfaces.md) | Some servers may have redundant management interfaces or extra NICs which you never expect to come up. This can delay startup. This document discusses how to push configurations to enable or disable network interfaces.
[Dual Interface Metal (Public/Private adapters)](nodes-with-dual-interfaces.md) | You may be doing an OKD deployment where the nodes have multiple interfaces (e.g one for public and one for private). This document goes over some gotchas this has and also firewalls to ensure cluster traffic goes over the private address space where possible
[Customising hostname logic](node-hostname-resolution.md) | Misconfigured hostnames will cause clusters to fail in bizaare ways. Sometimes you may not have the infrastructure 
[Setting a Node IP](nodes-where-you) | sdf




