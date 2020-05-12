# Install OKD 4 on Azure
This guide explains how to install OKD 4 on Azure. So far (as of 2020-05-12) the OKD 4 installer for Azure still needs to download the Fedora Core OS image to the local disk, decompress it and upload the decompressed image to an Azure storage again. 

Because the download and especially the upload of the decompressed image takes a long time, it can happen that the installer stops with a timeout. 

This guide describes a workaround to get OKD 4 installed on Azure. It will not be necessary anymore at the time when the Fedora Core OS image is available in the Azure Marketplace. The assumption is, that the download and upload speeds are dramatically increased if you run the installer for OKD 4 directly on Azure in an Azure Cloud Shell (the procedure also works if you run the installer in an Azure VM but it's simpler to use the Cloud Shell).

## Assumptions
- You have access to an [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview). This guide assumes that you chose Linux for your Cloud Shell.
- You have created a [Service Principle for OKD 4 in Azure](https://docs.openshift.com/container-platform/4.4/installing/installing_azure/installing-azure-account.html)
- You downloaded the openshift-installer and oc for the OKD version you're installing in your PATH. See [Getting Started](/README.md#getting-started)
- The openshift-installer should be either from [Beta5](https://origin-release.svc.ci.openshift.org/) or higher or a nightly build newer than 2020-05-11

## Procedure

### Open Azure Cloud Shell
Just do it.

### Check if you have enough space for the downloaded FCOS image
At least in my Azure Cloud Shell I have not enough space in my home directory to store the downloaded and decompressed FCOS image (~8 GByte are necessary).

```
df -h
```

If */home/\<YOUR USERNAME\>* shows less than 10 GByte free storage, you must create a symlink for the hidden .cache directory to a place where enough disk storage is available. In my case */home* was mounted to a drive with sufficient disk space.


e.g.: 

```
cd ~
mkdir /home/cache
ln -s /home/cache /home/<YOUR USERNAME/.cache
```

### Install OKD 4 on Azure
Now you can start the installation procedure by calling

```
openshift-install create cluster
```

### Prevent the Azure Cloud Shell session from being automatically closed
There is a timeout for Azure Cloud Shells of ~ 10-20 minutes. You have to press ENTER in the Cloud Shell regularly to prevent your session from being automatically closed. Alternatively you could use tmux or screen (but haven't tried them out yet on my own).


### Watch the installation procedure
It will take a few minutes until the bootstrap and master VMs are in running state. If you like to watch how the OKD cluster comes to life you can do this:


```
export KUBECONFIG=auth/kubeconfig
watch -n 1 oc get clusterversion/version
```
### Login to the OKD console

If the openshift-console pods are up and running you should be able to login in your newly created cluster:


The initial credentials are:
```
username: kubeadmin
password: $(cat auth/kubeadmin-password)
```

### Have fun
Thats all. Enjoy your new OKD 4 cluster on Azure :-)
