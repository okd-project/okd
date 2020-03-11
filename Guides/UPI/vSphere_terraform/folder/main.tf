resource "vsphere_folder" "folder" {
  path          = var.path
  type          = "vm"
  datacenter_id = var.datacenter_id
}
