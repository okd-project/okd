# Frequent issues in latest releases

## [Some optional operators from OCP are not available in OKD](https://github.com/openshift/okd/issues/456)
  **Affected Versions:** All

  **Description:** OCP users can install Logging/Serverless/GPU and other operators from Red Hat OperatorHub. This requires redhat.io pull secret, which may not be available for OKD users.

  **Workaround:** Start installation with a pull secret from cloud.redhat.com, enable new source in operatorhub settings.

  OKD-specific catalog with community versions of mentioned operators is in progress.

## [CephFS mounts get invalid permissions](https://github.com/openshift/okd/issues/1160)
  **Effected Versions:** 4.10.0-0.okd-2022-03-07-131213
  **Description:** Due to kernel 4.16 bug CephFS mounts get invalid permissions, so writing to image registry backed by CephFS fails on OKD 4.10
  **Workaround**: In `ceph-csi-cephfs` installation add `wsync` to `kernelMountOptions`
