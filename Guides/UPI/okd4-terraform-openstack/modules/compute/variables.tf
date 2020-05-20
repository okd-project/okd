variable "cluster_name" {}

variable "number_of_boot" {}

variable "number_of_masters" {}

variable "number_of_workers" {}

variable "master_volume_size" {}

variable "node_volume_size" {}

variable "dns_zone_id" {}

variable "public_key_path" {}

variable "ssh_user" {}

variable "image" {}

variable "image_lb" {}

variable "flavor_master" {}

variable "flavor_worker" {}

variable "flavor_lb" {}

variable "network_name" {}

variable "domain_name" {}

variable "master_ignition" {}

variable "worker_ignition" {}

variable "boot_ignition" {}

variable "allow_ssh_from_v4" {
  type = list(string)
  default = []
}
