OKD Installer Workspace
---
When deploying onto any UPI, but especially bare metal, it's likely that you will need to adapt your install methodology and process to the environment within.

The nature of the `openshift-installer` is that it eats configs and manifests as it progresses through creating the necessary steps.

This can be frustrating when you are trying to rapidly iterate on configuration changes as you re-provision your cluster.

The OKD Installer Workspace is a set of bash scripts which is designed to ease the pain of re-deploys and provide a sane way of managing configuration.

The workspace is designed to be actively hacked on you. You will likely want to create a personal version and modify the scripts to do actions such as automatically upload the provided ignition files or 

The OKD Installer workspace project can be found [here](https://github.com/GingerGeek/okd-installer-workspace)
