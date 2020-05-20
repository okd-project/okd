#!/bin/bash
#
# This script automates generation of openshift UPI installer dir, makes
# ignition files available for terraform for openstack provisioning,
# and redirects bootstrap node ignition-config to fetch from s3-bucket
# This is necessary due to size limitation of POST-request in the openstack API
# The bootstrap ignition file is posted as user_data and trips the limit for the size of
# the whole POST request.
# The script uses the aws cli to put ignition file to a bucket
# aws cli must be configured with credentials allowing it to copy files to the <s3-endpoint-url>
# given as argument number two to this script.
#
# s3 presign expires after default 3600s, so terraforming the bootstrap node must be done
# so the ignition config can be fetched before prsign of the ignition bucket expires
#
# Take care to exit editor after editing "installer/manifests/cluster-scheduler-02-config.yml"
# so there is no lock/swap files floating around in the install directory when ignition files
# when directory contents are wrapped into ignition conigs in the next steps. It can hamper the installation
# process. It did for me :-)

set -eo pipefail

s3_endpoint_url="$2"
install_config=$1
installer_dir="installer"
installer="./openshift-install"

if [[ -z $2 ]]
then
  echo "Usage: $0 <install-config-file> <s3-endpoint-url>"
  exit 1
fi


function make_bootstrap_ignition {
cat << EOF
{
  "ignition": {
    "version": "3.0.0",
    "config": {
      "replace": {
        "source": "${ignition_url}",
        "verification": {}
      }
    }
  }
}
EOF
}

function ignition_s3 {
  aws --profile ignition --endpoint-url ${s3_endpoint_url} s3 $@
}

function ignition_s3_cp {
  out="$(ignition_s3 rm s3://ignition/$1)"
  out="$(ignition_s3 cp $1 s3://ignition/)"
  ignition_s3 presign "s3://ignition/$(basename $1)"
}


rm -rf ${installer_dir} 
mkdir ${installer_dir}
cp $install_config ${installer_dir}/install-config.yaml
${installer} --dir=${installer_dir} create manifests
echo "Edit ${installer_dir}/manifests/cluster-scheduler-02-config.yml"
echo "and hit return when done"
read
${installer} --dir=${installer_dir} create ignition-configs 
ignition_url="$(ignition_s3_cp ${installer_dir}/bootstrap.ign)"
make_bootstrap_ignition > ${installer_dir}/bootstrap.ign

# Init terraform code
terraform init

# Override defaul values with 0 nodes and 1 boot
terraform apply -auto-approve -var=number_of_workers=0 -var=number_of_boot=1

curl -s -o inventory/terraform.py https://raw.githubusercontent.com/kubernetes-sigs/kubespray/master/contrib/terraform/terraform.py
chmod +x inventory/terraform.py

while true
do
  if ansible-playbook -i inventory/wrapper.sh update-lb.yaml
  then
    break
  fi
  sleep 5
done

./openshift-install --dir=${installer_dir} wait-for bootstrap-complete 


# Apply with default values
terraform apply -auto-approve

# Update lb from new inventory
ansible-playbook -i inventory/wrapper.sh update-lb.yaml

export KUBECONFIG=installer/auth/kubeconfig

./oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve
sleep 60
./oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve
