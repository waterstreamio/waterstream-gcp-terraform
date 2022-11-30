variable project {
  type = string
  description = "todo-add-your-gcp-project-name"
}

variable "region" {
}

variable "zone" {
}

variable "node_type" {
#  default = "n1-standard-1"
  default = "n1-standard-2"
}

variable "gke_disk_type" {
  type        = string
  default     = "pd-standard"
}

variable "kafka_disk_size_gb" {
  type        = string
  default     = "500"
}

#variable "node_disk_size_gb" {
#  type = number
#  default = 500
#}

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.3.0.0/16"
}

variable "confluent_version" {
  type = string
  default = "7.0.1"
}


###########################################
#############     DockerHub   #############
###########################################

variable "dockerhub_username" {
  type = string
}

variable "dockerhub_password" {
  type = string
}
