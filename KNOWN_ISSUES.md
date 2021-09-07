# Frequent issues in latest releases

## [Single-node Cluster Installations Fails on AWS (IPI)](https://github.com/openshift/okd/issues/862)

  **Effected Versions:** 4.7

  **Description:** Attempting to deploy a single-node cluster to AWS with Installer Provisioned Infrastructure (IPI) fails.

  **Workaround:** None at this time. 

## CannotRetrieveUpdates alert

  **Effected Versions:** All

  **Description:** Installed clusters throw `CannotRetrieveUpdates` alert, origin-release.svc.ci.openshift.org is unreachable.
  This domain was deprecated during CI Infra cleanup. Unfortunately we didn't rollout the fix to change this URL in OKD.

  **Workaround:** `oc patch clusterversion/version --patch '{"spec":{"upstream":"https://amd64.origin.releases.ci.openshift.org/graph"}}' --type=merge`

## [Provision node fails with fcos image 33.20210301.3.1 and later](https://github.com/openshift/okd/issues/566)
  **Effected Versions:** 4.7.0-0.okd-2021-02-25-144700 - 4.7.0-0.okd-2021-06-04-191031

  **Description:** Update Fedora CoreOS images are using a new method of extended attributes check, breaking extraction of embedded OS extensions RPMs.

  **Workaround:** Use FCOS 33.20210217.3.0 - [ISO](https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210217.3.0/x86_64/fedora-coreos-33.20210217.3.0-live.x86_64.iso)

  Resolved in 4.7.0-0.okd-2021-06-13-090745 - latest stable FCOS can be used to create a cluster.

## [Invalid signature error when attempting cluster updates](https://github.com/openshift/okd/issues/605)
  **Effected Versions:** 4.7.0-0.okd-2021-04-11-124433 and 4.7.0-0.okd-2021-05-22-050008

  **Description:** Cluster upgrades will not start due to incorrect image signatures.

  **Workaround:** Perform the upgrade in the terminal using the --force and --allow-upgrade-with-warnings flags after first resetting any in-process upgrades.
  ```bash
  oc adm upgrade --reset
  oc adm upgrade --to-latest=true --force=true --allow-upgrade-with-warnings
  ```
  You can also patch the clusterversion configuration
  ```bash
  oc patch clusterversion version --type="merge" -p '{"spec":{"desiredUpdate":{"force":true}}}'
  ```

  New signing key is used in `4.7.0-0.okd-2021-05-22-050008`, so newer releases would pass signature check correctly.

## [Some optional operators from OCP are not available in OKD](https://github.com/openshift/okd/issues/456)
  **Effected Versions:** All

  **Description:** OCP users can install Logging/Serverless/GPU and other operators from Red Hat OperatorHub. This requires redhat.io pull secret, which may not be available for OKD users.

  **Workaround:** Start installation with a pull secret from cloud.redhat.com, enable new source in operatorhub settings.

  OKD-specific catalog with community versions of mentioned operators is in progress.

## [Systemd-resolved is not configured properly during install](https://github.com/openshift/okd/issues/690)
  **Effected Versions:**  4.7.0-0.okd-2021-06-13-090745 - 4.7.0-0.okd-2021-06-13-090745

  **Description:** With the newest stable release, systemd-resolved is misconfigured due to a missing directory.  This prevents nodes from installing properly.
  
  **Workaround** from each affected node do the following
* sudo su -
* mkdir /etc/systemd/resolved.conf.d
* reboot

## [systemd crash with CoreOS stable 34.20210711.3.0](https://github.com/coreos/fedora-coreos-tracker/issues/912)

  **Affected Versions:**  4.7.0-0.okd-2021-08-07-063045 - 4.7.0-0.okd-2021-08-07-063045

  **Description:** Systemd version systemd-248.5-1.fc34.x86_64 may core dump with this message:

  ```
systemd[1]: Caught <ABRT>, dumped core as pid 3444.
systemd[1]: Freezing execution.
  ```
  As an initial symptom, the node may have slowness and timeouts for interactive ssh and sudo. From the perspective of the Kubernetes scheduler, the nodes are available but pods created after ABRT report when using "get pod" ContainerCreating and when using "describe pod" a Status of Pending.

  Because of [two CVEs](https://github.com/coreos/fedora-coreos-tracker/issues/904) package updates were fast-tracked. Afterwards, as noted in [an issue](https://github.com/coreos/fedora-coreos-tracker/issues/912) and [Bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=1984651), systemd may respond as if sent an ABRT signal and crash. Differences between systemd-248.5 and 248.6 are listed at [Bodhi](https://bodhi.fedoraproject.org/updates/FEDORA-2021-3141f0eff1). A [commit](https://github.com/openshift/okd-machine-os/pull/181) to remove the package exceptions from okd-machine-os was made in mid-August 2021.

  Updated systemd package landed in 4.7.0-0.okd-2021-08-22-163618

  **Workaround:** Reboot the machine when systemd crashes.
