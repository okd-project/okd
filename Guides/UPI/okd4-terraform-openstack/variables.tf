variable "cluster_name" {
  default = "example"
}

variable "boot_ignition" {
  default = "{}"
}
variable "master_ignition" {
  default = "{}"
}

variable "worker_ignition" {
  default = "{}"
}

variable "public_key_path" {
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  default = "centos"
}

variable "dns_zone_id" {
  default = ""
}

variable "number_of_boot" {
  default = 1
}

variable "number_of_masters" {
  default = 1
}

variable "number_of_workers" {
  default = 0
}

variable "master_volume_size" {
  default = 20
}

variable "node_volume_size" {
  default = 20
}

variable "image_lb" {
  description = "the image to use (LB)"
  default     = "GOLD CentOS 7"
}
variable "image" {
  description = "the image to use (cluster)"
  default     = "fedora-coreos-31.20200118.3.0"
}

variable "flavor_master" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default     = 3
}

variable "flavor_worker" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default     = 3
}

variable "flavor_lb" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default     = 3
}

variable "network_name" {
  description = "name of the internal network to use"
  default     = "dualstack"
}

variable "domain_name" {
  description = "DNS domain name"
  default     = "example.uiocloud.no"
}

variable "allow_ssh_from_v4" {
  type = list(string)
  default = []
}

