# Number of VMs for Ubuntu-Web
variable "instance_count" {
  default = "3"
}

variable "eks_nodes_desired_size" {
  default = "2"
}

variable "eks_nodes_max_size" {
  default = "2"
}

variable "eks_nodes_min_size" {
  default = "1"
}