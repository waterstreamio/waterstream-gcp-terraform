provider "google" {
#  credentials = file("account.json")
  credentials = file("../account.json")
  project = var.project
  region = var.region
  zone = var.zone
}

# Use a random suffix to prevent overlap in network names
resource "random_string" "suffix" {
  length = 4
  special = false
  upper = false
}

resource "google_compute_address" "kafka_ip" {
  name = "wsdemo-kafka-ip"
}


resource "google_compute_instance" "waterstream" {
  name = "wsdemo-kafka"
  description = "Creates a machine with ZK+Kafka, initialized topics for the Waterstream"


  tags = ["waterstream", "waterstream-demo", "kafka", terraform.workspace]

  #  depends_on = [google_compute_router_nat.nat]

  labels = {
    environment = "demo"
    app = "waterstream-demo"
    demo-instance = terraform.workspace
  }

  machine_type = var.node_type
  #  can_ip_forward = false

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"

      //most space go to /mnt/stateful_partition
      size = var.kafka_disk_size_gb
      type = var.gke_disk_type
    }

    auto_delete = true
  }

  network_interface {
    network = "default"

    access_config {
      //ephemeral IP
      nat_ip = google_compute_address.kafka_ip.address
    }
  }

  metadata = {
    app = "waterstream"
    env-name = terraform.workspace
    tf-config-sh = <<EOF
#!/bin/sh
  export CONFLUENT_VERSION=${var.confluent_version}
EOF
    config-sh = file("content/config.sh")
    start-kafka-sh = file("content/startKafka.sh")
    create-topics-sh = file("content/createTopics.sh")
    user-data = <<EOF
#cloud-config

users:
  - name: wsdemo
    groups: docker
runcmd:
  - mkdir /var/waterstream
  - cd /var/waterstream
  - echo Waterstream demo Kafka >> init.log
  - echo scripts download start >> init.log
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/tf-config-sh", -H, "Metadata-Flavor: Google", -o, tfConfig.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-sh", -H, "Metadata-Flavor: Google", -o, config.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/start-kafka-sh", -H, "Metadata-Flavor: Google", -o, startKafka.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/create-topics-sh", -H, "Metadata-Flavor: Google", -o, createTopics.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip", -H, "Metadata-Flavor: Google", -o, external_ip.txt]
  - EXTERNAL_IP=`cat external_ip.txt`
  - echo scripts download done >> init.log
  - chmod a+x *.sh
  - chown wsdemo *
  - sudo -u wsdemo docker login -u ${var.dockerhub_username} -p ${var.dockerhub_password}
  - sudo -u wsdemo sh startKafka.sh $EXTERNAL_IP > kafka_start.log 2>&1
  - sudo -u wsdemo sh createTopics.sh >> kafka_start.log 2>&1
  - echo ZK, Kafka start done >> init.log
  - echo init done >>  init.log
EOF
  }

  service_account {
    scopes = [
      "userinfo-email",
      "compute-ro",
      "storage-ro",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }

  //  desired_status = "TERMINATED"
}

output "kafka_ip" {
  value = google_compute_address.kafka_ip.address
}


