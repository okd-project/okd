#!/bin/bash

while getopts ":t:c:d:f:n:" opt; do
  case $opt in
	t) template_name="$OPTARG"
	;;
	c) cluster_name="$OPTARG"
	;;
	d) datastore_name="$OPTARG"
	;;	
	f) vm_folder="$OPTARG"	    
	;;
	n) network_name="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Cluster: ${cluster_name}"
echo "Template: ${template_name}"
echo "Datastore: ${datastore_name}"
echo "Folder: ${vm_folder}"
echo "Network: ${network_name}"

master_node_count=3
master_node_base_name="${cluster_name}-master-"
worker_node_count=3
worker_node_base_name="${cluster_name}-worker-"
bootstrap_node_name="${cluster_name}-bootstrap"

# Create the master nodes

for (( i=1; i<=${master_node_count}; i++ )); do
        vm=${master_node_base_name}${i}
	govc vm.clone -vm "${template_name}" \
		-ds "${datastore_name}" \
		-folder "${vm_folder}" \
		-on="false" \
		-c="4" -m="8192" \
		-net="${network_name}" \
		$vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G
done

# Create the worker nodes

for (( i=1; i<=${worker_node_count}; i++ )); do
        vm=${worker_node_base_name}${i}
        govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="4" -m="8192" \
                -net="${network_name}" \
                $vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G
done


# Create the bootstrap node

vm=${bootstrap_node_name}
govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="4" -m="8192" \
                -net="${network_name}" \
                $vm
govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size 120G


# Set metadata on the master nodes

for (( i=1; i<=${master_node_count}; i++ )); do
        vm=${master_node_base_name}${i}
	govc vm.change -vm $vm \
		-e guestinfo.ignition.config.data="$(cat master.ign | base64 -w0)" \
		-e guestinfo.ignition.config.data.encoding="base64" \
		-e disk.EnableUUID="TRUE"
done

# Set metadata on the worker nodes

for (( i=1; i<=${worker_node_count}; i++ )); do
        vm=${worker_node_base_name}${i}
	govc vm.change -vm $vm \
                -e guestinfo.ignition.config.data="$(cat worker.ign | base64 -w0)" \
                -e guestinfo.ignition.config.data.encoding="base64" \
                -e disk.EnableUUID="TRUE"
done

# Set metadata for the bootstrap

vm=${bootstrap_node_name}
govc vm.change -vm $vm \
	-e guestinfo.ignition.config.data="$(cat append-bootstrap.ign | base64 -w0)" \
	-e guestinfo.ignition.config.data.encoding="base64" \
	-e disk.EnableUUID="TRUE"
