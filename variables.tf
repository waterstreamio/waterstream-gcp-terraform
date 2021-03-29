variable project {
  type = string
  description = "todo-add-your-gcp-project-name"
}

variable "region" {
}

variable "zone" {
}

variable "node_type" {
  default = "n1-standard-1"
}

variable "monitoring_node_type" {
  default = "n1-standard-1"
}

variable "preemptible_nodes" {
  default = "false"
}

variable cluster_name {
  default = "waterstream-demo-cluster"
  type = string
}

variable "waterstream_ram_percentage" {
  description = "JVM MaxRAMPercentage parameter value"
  type        = number
  default     = 80
}

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.3.0.0/16"
}

variable "mqttd_version" {
  type        = string
  default     = "1.3.12"
}

variable "mqttd_replicas_count" {
  type        = string
  default     = "3"
}

variable "kafka_streams_replication_factor" {
  type        = number
  default     = 3
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

###########################################
############# Confluent Cloud #############
###########################################

variable "bootstrap_server" {
}

variable "ccloud_api_key" {
}

variable "ccloud_api_secret" {
}

