#!/bin/bash


set -eo pipefail

function openstack-image-create {
  file=$1
  name=$2
  /home/jb/virtualenv/bin/openstack image create --disk-format qcow2 --min-disk 9 --min-ram 768 --private --file "$file" "$name"
}

repo="registry.svc.ci.openshift.org/origin/release"
if  [[ -z $2 ]]
then
  echo "Usage: $0 <okd-release> <fcos-image-version>"
  exit 2
fi

release="$1"
image_ver="${2}.0"
fcos_repo="https://builds.coreos.fedoraproject.org/prod/streams/testing-devel/builds"
arch="x86_64"
fcos_file="fedora-coreos-${image_ver}-openstack.${arch}.qcow2.xz"

# 31.20200323.20.0/x86_64/fedora-coreos-31.20200323.20.0-gcp.x86_64.tar.gz"
echo "Downloding FCOS image"
curl -O "${fcos_repo}/${image_ver}/${arch}/${fcos_file}"

echo "decompressing image" 
xz -f -d ${fcos_file}
fcos_file_decompressed="$(basename -s .xz ${fcos_file})"

openstack_image_name="fcos-${image_ver}"
echo "Uploading image file to: ${openstack_image_name}"
openstack-image-create "${fcos_file_decompressed}" "${openstack_image_name}"

cp README.md README.md.orig
echo "Extracting tools for okd version ${release}"
oc4 adm release extract --tools ${repo}:${release}
tar zxvf "openshift-install-linux-${release}.tar.gz" 
tar zxvf "openshift-client-linux-${release}.tar.gz" 
cp README.md.orig README.md

