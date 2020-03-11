//////
// vSphere variables
//////

variable "vsphere_server" {
  type        = string
  description = "This is the vSphere server for the environment."
}

variable "vsphere_user" {
  type        = string
  description = "vSphere server user for the environment."
}

variable "vsphere_password" {
  type        = string
  description = "vSphere server password"
}

variable "vsphere_cluster" {
  type        = string
  description = "This is the name of the vSphere cluster."
}

variable "vsphere_datacenter" {
  type        = string
  description = "This is the name of the vSphere data center."
}

variable "vsphere_datastore" {
  type        = string
  description = "This is the name of the vSphere data store."
}

variable "vm_template" {
  type        = string
  description = "This is the name of the VM template to clone."
}

variable "vm_network" {
  type        = string
  description = "This is the name of the publicly accessible network for cluster ingress and access."
  default     = "VM Network"
}

/////////
// OpenShift cluster variables
/////////

variable "cluster_id" {
  type        = string
  description = "This cluster id must be of max length 27 and must have only alphanumeric or hyphen characters."
}

variable "base_domain" {
  type        = string
  description = "The base DNS zone to add the sub zone to."
}

variable "cluster_domain" {
  type        = string
  description = "The base DNS zone to add the sub zone to."
}

/////////
// Bootstrap machine variables
/////////

variable "bootstrap_complete" {
  type    = string
  default = "false"
}

variable "bootstrap_ignition" {
  type = string
}

variable "bootstrap_mac" {
  type    = string
  default = ""
}

///////////
// Control Plane machine variables
///////////

variable "control_plane_count" {
  type    = string
  default = "3"
}

variable "control_plane_ignition" {
  type = string
}

variable "control_plane_macs" {
  type    = list
  default = []
}

//////////
// Compute machine variables
//////////

variable "compute_count" {
  type    = string
  default = "3"
}

variable "compute_ignition" {
  type = string
}

variable "compute_macs" {
  type    = list
  default = []
}
