# Frequent issues in latest releases

## [Unable to mirror images from quay](https://github.com/openshift/okd/issues/402)
  **Effected Versions:** All  
  **Description:**  Attempts to mirror content on the quay repository fails. This blocks air-gapped installs on restricted networks. The fix needs to land in our buildfarms and all images rebuilt.  
  **Workaround**: None available at this time. 

## [Invalid signature error when attempting cluster updates](https://github.com/openshift/okd/issues/426)
  **Effected Versions:** 4.6.0-0.okd-2020-11-27-200126, 4.6.0-0.okd-2020-12-12-135354, 4.6.0-0.okd-2021-01-17-185703  
  **Description:** Cluster upgrades will fail due to incorrect image signatures.   
  **Workaround:** Perform the upgrade in the terminal using the --force and --allow-upgrade-with-warnings flags after first resetting any in-process upgrades.  
  ```bash
  oc adm upgrade --reset
  oc adm upgrade --to-latest=true --force=true --allow-upgrade-with-warnings     
  ```
  You can also patch the clusterversion configuration
  ```bash
  oc patch clusterversion version --type="merge" -p '{"spec":{"desiredUpdate":{"force":true}}}'
  ```

## [OpenshiftSDN: install or upgrade to 4.6 fails](https://github.com/openshift/okd/issues/430)
  **Effected Versions:** 4.6.0-0.okd-2020-11-27-200126 and greater  
  **Description:** There are two Software Defined Networking providers in Openshift: Openshift's default offering OpenshiftSDN and the Kubernetes community supported OVNKubernetes. OpenshiftSDN has a routing bug that prevents proper operation. OVNKubernetes works as expected.      
  **Workaround:** Avoid upgrading clusters using OpenshiftSDN and/or [Migrate to the OVNKubernetes plugin](https://docs.okd.io/latest/networking/ovn_kubernetes_network_provider/migrate-from-openshift-sdn.html)

