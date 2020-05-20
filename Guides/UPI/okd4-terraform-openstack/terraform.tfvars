cluster_name = "okd4-test"      // Cluster name
image = "fcos-31.20200420.20.0" // Image to use in openstack
domain_name = "the.subdomain.in.openstack"  // The subdomain in your openstack project. 


flavor_master = "the-id-of-a-flavor-with-16GB-ram-or-more"
flavor_worker   = "worker-flavor-id"
flavor_lb     = "loadbalancer-falvor-id"

dns_zone_id = "dns-zone-id"

number_of_masters = 3 // Final number of masters
number_of_workers = 2 // Final number of workers
number_of_boot = 0

boot_ignition = "./installer/bootstrap.ign"
master_ignition = "./installer/master.ign"
worker_ignition = "./installer/worker.ign"

network_name = "name-of-the-network-for-openstack-instances"

allow_ssh_from_v4 = [
    "CIDR-Range-to-allow-ssh-into-instances",
    "one-more"
]

