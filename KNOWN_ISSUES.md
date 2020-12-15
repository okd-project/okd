# Frequent issues in latest stable release

## [Unable to mirror images from quay](https://github.com/openshift/okd/issues/402)
  This blocks air-gapped installs, the fix needs to land in our buildfarms and all images rebuild.

## [Invalid signature store used](https://github.com/openshift/okd/issues/426)
  Upgrades to latest stable version require `--force` when `oc adm upgrade` call
