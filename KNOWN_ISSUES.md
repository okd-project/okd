# Frequent issues in latest releases

## [Some optional operators from OCP are not available in OKD](https://github.com/openshift/okd/issues/456)
  **Effected Versions:** All

  **Description:** OCP users can install Logging/Serverless/GPU and other operators from Red Hat OperatorHub. This requires redhat.io pull secret, which may not be available for OKD users.

  **Workaround:** Start installation with a pull secret from cloud.redhat.com, enable new source in operatorhub settings.

  OKD-specific catalog with community versions of mentioned operators is in progress.
