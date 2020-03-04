provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

module "folder" {
  source = "./folder"

  path          = var.cluster_id
  datacenter_id = data.vsphere_datacenter.dc.id
}

module "resource_pool" {
  source = "./resource_pool"

  name            = var.cluster_id
  datacenter_id   = data.vsphere_datacenter.dc.id
  vsphere_cluster = var.vsphere_cluster
}

module "bootstrap" {
  source = "./machine"

  name                 = "bootstrap"
  instance_count       = var.bootstrap_complete ? 0 : 1
  ignition             = var.bootstrap_ignition
  resource_pool_id     = module.resource_pool.pool_id
  datastore            = var.vsphere_datastore
  folder               = module.folder.path
  network              = var.vm_network
  datacenter_id        = data.vsphere_datacenter.dc.id
  template             = var.vm_template
  cluster_domain       = var.cluster_domain
  mac_addresses        = compact(list(var.bootstrap_mac))
  memory               = "8192"
  num_cpu              = "4"
  num_cores_per_socket = "4"
  disk_size            = "60"
}

module "master" {
  source = "./machine"

  name                 = "master"
  instance_count       = var.control_plane_count
  ignition             = var.control_plane_ignition
  resource_pool_id     = module.resource_pool.pool_id
  folder               = module.folder.path
  datastore            = var.vsphere_datastore
  network              = var.vm_network
  datacenter_id        = data.vsphere_datacenter.dc.id
  template             = var.vm_template
  cluster_domain       = var.cluster_domain
  mac_addresses        = var.control_plane_macs
  memory               = "16384"
  num_cpu              = "4"
  num_cores_per_socket = "4"
  disk_size            = "60"
}

module "compute" {
  source = "./machine"

  name                 = "worker"
  instance_count       = var.compute_count
  ignition             = var.compute_ignition
  resource_pool_id     = module.resource_pool.pool_id
  folder               = module.folder.path
  datastore            = var.vsphere_datastore
  network              = var.vm_network
  datacenter_id        = data.vsphere_datacenter.dc.id
  template             = var.vm_template
  cluster_domain       = var.cluster_domain
  mac_addresses        = var.compute_macs
  memory               = "8192"
  num_cpu              = "4"
  num_cores_per_socket = "4"
  disk_size            = "60"
}
