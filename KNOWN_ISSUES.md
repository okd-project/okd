# Frequent issues in latest releases

## [Some optional operators from OCP are not available in OKD](https://github.com/openshift/okd/issues/456)
  **Affected Versions:** All
   Please see [this explanation of Operator availability on OKD](https://www.okd.io/okd_tech_docs/operators/). An OKD-specific catalog with community versions of mentioned operators is in progress.

## [CephFS mounts get invalid permissions](https://github.com/openshift/okd/issues/1160)
  **Effected Versions:** 4.10.0-0.okd-2022-03-07-131213
  **Description:** Due to kernel 4.16 bug CephFS mounts get invalid permissions, so writing to image registry backed by CephFS fails on OKD 4.10
  **Workaround**: In `ceph-csi-cephfs` installation add `wsync` to `kernelMountOptions`

## [Ceph service performance degradation](https://github.com/okd-project/okd/issues/1505)
  **Effected Versions:** 4.11.0-0.okd-2023-01-14-152430, 4.12.0-0.okd-2023-02-04-212953
  **Description:** Due to kernel 6.0 bug with bind(), the Ceph service faces radical performance degradation, causing PG unavailability, very slow I/O operations.
  **Workaround**: Either build a custom [FCOS image using layering](https://docs.okd.io/4.12/post_installation_configuration/coreos-layering.html) or update to a newer version.
