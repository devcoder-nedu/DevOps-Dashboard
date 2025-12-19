variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_count" {
  description = "Number of nodes in the pool"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Type of machine for the nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  default = 30
}
variable "disk_type" {
  default = "pd-standard"
}