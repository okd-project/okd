variable "name" {
  type = string
}

variable "instance_count" {
  type = string
}

variable "ignition" {
  type    = string
  default = ""
}

variable "resource_pool_id" {
  type = string
}

variable "folder" {
  type = string
}

variable "datastore" {
  type = string
}

variable "network" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "datacenter_id" {
  type = string
}

variable "template" {
  type = string
}

variable "mac_addresses" {
  type = list
}
variable "memory" {
  type = string
}

variable "num_cpu" {
  type = string
}

variable "num_cores_per_socket" {
  type = string
}

variable "disk_size" {
  type = string
}
