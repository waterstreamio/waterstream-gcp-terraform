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

variable "node_disk_size_gb" {
  type = number
  default = 10
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

variable "waterstream_version" {
  type        = string
  default     = "1.4.9"
}

variable "waterstream_replicas_count" {
  type        = string
  default     = "3"
}

variable "waterstream_kafka_linger_ms" {
  type        = number
  default     = 0
}

variable "waterstream_kafka_batch_size" {
  type        = number
  default     = 16348
}

variable "waterstream_kafka_compression_type" {
  type        = string
  default     = "snappy"
}

variable "kafka_streams_replication_factor" {
  type        = number
  default     = 3
}

variable "waterstream_centralized_consumer_listener_queue" {
  type        = number
  default     = 32
}



###########################################
#############     DockerHub   #############
###########################################

#For tests that involve private images

variable "dockerhub_username" {
  default = ""
  type = string
}

variable "dockerhub_password" {
  default = ""
  type = string
}

###########################################
############# Confluent Cloud #############
###########################################
#
#variable "bootstrap_server" {
#}
#
#variable "ccloud_api_key" {
#}
#
#variable "ccloud_api_secret" {
#}
#

###############################################################
## Kafka cluster connection
###############################################################

variable "kafka_bootstrap_servers" {
  type = string
}

variable "kafka_sslEndpointIdentificationAlgorithm" {
  type = string
  description = "ssl.endpoint.identification.algorithm for producer and consumer"
  default = ""
}

variable "kafka_saslJaasConfig" {
  description = "sasl.jaas.config for producer and consumer"
  type = string
  default = ""
}

variable "kafka_saslMechanism" {
  type = string
  description = "`sasl.mechanism` for producer and consumer"
  default = ""
}

variable "kafka_securityProtocol" {
  type = string
  description = "security.protocol for producer and consumer"
  default = "PLAINTEXT"
}

variable "kafka_requestTimeoutMs" {
  type = number
  description = "request.timeout.ms for producer and consumer"
  default = 30000
}
