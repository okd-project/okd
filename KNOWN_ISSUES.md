# Frequent issues in latest releases

## [Single-node Cluster Installations Fails on AWS (IPI)](https://github.com/openshift/okd/issues/862)

  **Effected Versions:** 4.7

  **Description:** Attempting to deploy a single-node cluster to AWS with Installer Provisioned Infrastructure (IPI) fails.

  **Workaround:** None at this time. OKD 4.8 is known to work

## CannotRetrieveUpdates alert

  **Effected Versions:** All versions before 4.7.0-0.okd-2021-09-19-013247 or 4.8.0-0.okd-2021-10-01-221835

  **Description:** Installed clusters throw `CannotRetrieveUpdates` alert, origin-release.svc.ci.openshift.org is unreachable.
  This domain was deprecated during CI Infra cleanup. Unfortunately we didn't rollout the fix to change this URL in OKD.

  **Workaround:** `oc patch clusterversion/version --patch '{"spec":{"upstream":"https://amd64.origin.releases.ci.openshift.org/graph"}}' --type=merge`

## [Some optional operators from OCP are not available in OKD](https://github.com/openshift/okd/issues/456)
  **Effected Versions:** All

  **Description:** OCP users can install Logging/Serverless/GPU and other operators from Red Hat OperatorHub. This requires redhat.io pull secret, which may not be available for OKD users.

  **Workaround:** Start installation with a pull secret from cloud.redhat.com, enable new source in operatorhub settings.

  OKD-specific catalog with community versions of mentioned operators is in progress.

## [Unable to mirror images OKD 4.8.0-0.okd-2021-10-01-221835](https://github.com/openshift/okd/discussions/904)
  **Effected Versions:** 4.8.0-0.okd-2021-10-01-221835
  **Description:**  Attempts to mirror 4.8 content on the CI registry fails. This blocks air-gapped installs on restricted networks. After https://github.com/openshift/okd/issues/402 was resolved some 4.8 images have not been rebuilt. The fix should be available in 4.8 nightlies.
  **Workaround**: None available at this time.
