provider "google" {
  credentials = file("account.json")
  project = var.project
  region = var.region
}

# Use a random suffix to prevent overlap in network names
resource "random_string" "suffix" {
  length = 4
  special = false
  upper = false
}

resource "google_compute_network" "net" {
  name = "${var.cluster_name}-network-${random_string.suffix.result}"
}

resource "google_compute_subnetwork" "subnet" {
  name = "${var.cluster_name}-subnetwork-${random_string.suffix.result}"
  network = google_compute_network.net.self_link
  ip_cidr_range = var.vpc_cidr_block
  region = var.region
}

resource "google_compute_router" "router" {
  name = "${var.cluster_name}-router-${random_string.suffix.result}"
  region = google_compute_subnetwork.subnet.region
  network = google_compute_network.net.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name = "${var.cluster_name}-router-nat-${random_string.suffix.result}"
  router = google_compute_router.router.name
  region = google_compute_router.router.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

//resource "google_compute_firewall" "mqttd-demo" {
//  name = "mqttd-demo"
//  network = google_compute_network.net.name
//
//  allow {
//    protocol = "icmp"
//  }
//
//  allow {
//    protocol = "tcp"
//    ports = [
//      "22",
//      "1883",
//      "1884",
//      "3000",
//      "9090"
//    ]
//  }
//
//  //  source_tags = [
//  //    "mqttd-demo"]
//  source_ranges = [
//    "0.0.0.0/0"]
//}

resource "google_compute_firewall" "mqttd-debug" {
  name = "${var.cluster_name}-mqttd-debug-${random_string.suffix.result}"
  network = google_compute_network.net.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "22",
      "1883",
      "1884"
    ]
  }

  target_tags = ["mqttd"]

  //  source_tags = [
  //    "mqttd-demo"]
  source_ranges = [
    "0.0.0.0/0"]
}

resource "google_compute_firewall" "mqttd-appserver" {
  name = "${var.cluster_name}-mqttd-appserver-${random_string.suffix.result}"
  network = google_compute_network.net.name

  allow {
    protocol = "tcp"
    ports = [
      "1882"
    ]
  }

  target_tags = ["mqttd"]

    source_tags = ["mqttd"]
}


resource "google_compute_firewall" "mqttd-monitoring" {
  name = "${var.cluster_name}-monitoring-${random_string.suffix.result}"
  network = google_compute_network.net.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "22",
      "3000",
      "9090"
    ]
  }

  target_tags = ["mqttd-monitoring"]

  //  source_tags = [
  //    "mqttd-demo"]
  source_ranges = [
    "0.0.0.0/0"]
}

resource "google_compute_forwarding_rule" "mqtt" {
  name = "mqttd-forwarding-mqtt"
  target = google_compute_target_pool.mqttd.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol = "TCP"
  port_range = "1883"
}

resource "google_compute_forwarding_rule" "monitoring" {
  name = "mqttd-forwarding-monitoring"
  target = google_compute_target_pool.mqttd.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol = "TCP"
  port_range = "1884"
}


resource "google_compute_instance_template" "mqttd" {
  name = "mqttd-template"
  description = "This template is used to create MQTTD server instances."

  tags = [
    "mqttd"]

  depends_on = [
    google_compute_router_nat.nat]

  labels = {
    environment = "test"
  }

  instance_description = "MQTTD instance instances"
  machine_type = var.node_type
  can_ip_forward = false

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete = true
    boot = true
  }

  network_interface {
    network = google_compute_network.net.id

    //uncomment to grant public IP
    //access_config { }
  }

  metadata = {
    app = "mqttd"
    mqttd-config-sh = file("mqttd/config.sh")
    mqttd-run-dockerized-sh = file("mqttd/runDockerized.sh")
    waterstream-license = file("waterstream.license")
    tf-config-sh = <<EOF
#!/bin/sh
export WATERSTREAM_VERSION=${var.waterstream_version}
export CCLOUD_API_KEY=${var.ccloud_api_key}
export CCLOUD_API_SECRET=${var.ccloud_api_secret}
export WATERSTREAM_RAM_PERCENTAGE=${var.waterstream_ram_percentage}
export KAFKA_STREAMS_APP_SERVER_HOST=`cat node_ip.txt`
export KAFKA_STREAMS_REPLICATION_FACTOR=${var.kafka_streams_replication_factor}
export KAFKA_PRODUCER_LINGER_MS=${var.waterstream_kafka_linger_ms}
export KAFKA_BATCH_SIZE=${var.waterstream_kafka_batch_size}
export KAFKA_COMPRESSION_TYPE=${var.waterstream_kafka_compression_type}
#Per-client queue length for reading messages from Kafka
export CENTRALIZED_CONSUMER_LISTENER_QUEUE=${var.waterstream_centralized_consumer_listener_queue}
EOF

    user-data = <<EOF
#cloud-config

users:
  - name: mqttd
    groups: docker
write_files:
  - path: /tmp/sample_file
    permissions: 0644
    owner: root
    content: |
      sample content
runcmd:
  - mkdir /var/mqttd
  - cd /var/mqttd
  - echo cluster ${var.cluster_name} >> mqttd_start.log
  - echo scripts download start >> mqttd_start.log
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/tf-config-sh", -H, "Metadata-Flavor: Google", -o, tfConfig.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mqttd-config-sh", -H, "Metadata-Flavor: Google", -o, config.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mqttd-run-dockerized-sh", -H, "Metadata-Flavor: Google", -o, runDockerized.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/waterstream-license", -H, "Metadata-Flavor: Google", -o, waterstream.license]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip", -H, "Metadata-Flavor: Google", -o, node_ip.txt]
  - echo scripts download done >> mqttd_start.log
  - sudo -u mqttd docker login -u ${var.dockerhub_username} -p ${var.dockerhub_password}
  - chmod a+x config.sh
  - chmod a+x runDockerized.sh
  - sleep 10
  - sudo -u mqttd sh runDockerized.sh
  - echo init done >>  mqttd_start.log
bootcmd:
  - mkdir /var/sample_boot_dir

EOF
  }

//For tests - log in to access private images:
//  - sudo -u mqttd docker login -u ${var.dockerhub_username} -p ${var.dockerhub_password}

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
}

data "google_compute_instance_group" "mqttd_nodes" {
  name = google_compute_instance_group_manager.mqttd_group.name
  zone = var.zone
}

data "google_compute_instance" "mqttd_nodes" {
  for_each = data.google_compute_instance_group.mqttd_nodes.instances
  self_link = each.key
}

data "local_file" "prometheus_yaml_template" {
  filename = "mqttd/prometheus.yaml.template"
}

output "prometheus_url" {
  value = format("http://%s:9090", google_compute_instance_from_template.mqttd_monitoring.network_interface.0.access_config.0.nat_ip)
}

output "grafana_url" {
  value = format("http://%s:3000", google_compute_instance_from_template.mqttd_monitoring.network_interface.0.access_config.0.nat_ip)
}

output "mqtt_lb_ip" {
  value = google_compute_forwarding_rule.mqtt.ip_address
}

output "monitoring_lb_ip" {
  value = google_compute_forwarding_rule.monitoring.ip_address
}

resource "google_compute_instance_template" "mqttd-monitoring" {
  name = "mqttd-monitoring-template"
  description = "This template is used to create MQTTD monitoring instances."

  tags = [
    "mqttd",
    "monitoring",
    "mqttd-monitoring"]

  depends_on = [
    google_compute_router_nat.nat
    //    local_file.prometheus_yaml
  ]

  labels = {
    environment = "test"
  }

  instance_description = "MQTTD monitoring instance"
  machine_type = var.monitoring_node_type
  can_ip_forward = false

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete = true
    boot = true
  }

  network_interface {
    network = google_compute_network.net.id

    //grant public IP
    access_config {}
  }

  metadata = {
    app = "mqttd-monitoring"
    mqttd-grafana-dashboard-json = file("mqttd/mqttd-grafana-dashboard-debug.json")
    prometheus-yaml = templatefile("mqttd/prometheus.yaml.template", {
      targetsStr: join(",", [for x in data.google_compute_instance.mqttd_nodes: format("'%s:%d'", x.network_interface.0.network_ip, 1884)])
    })

    //TODO substitute machine IP
    grafana-prometheus-datasource-yaml = <<EOF
apiVersion: 1

datasources:
- name: Prometheus
  type: prometheus
  # <string, required> access mode. proxy or direct (Server or Browser in the UI). Required
  access: proxy
  url: http://prometheus:9090
  isDefault: true
  editable: false
EOF

    grafana-dashboard-provider-yaml = <<EOF
apiVersion: 1

providers:
- name: 'Dashboards'
  folder: ''
  type: file
  disableDeletion: true
  editable: true
  updateIntervalSeconds: 30
  # <bool> allow updating provisioned dashboards from the UI
  allowUiUpdates: true
  options:
    path: /var/mqttd_monitoring_dashboards
EOF

    run-grafana-sh = <<EOF
#TODO provision anonymous organization for Grafana
docker run -d -v /var/mqttd_monitoring/datasource.yaml:/etc/grafana/provisioning/datasources/datasource.yaml \
              -v /var/mqttd_monitoring/dashboard-provider.yaml:/etc/grafana/provisioning/dashboards/provider.yaml \
              -v /var/mqttd_monitoring/dashboards:/var/mqttd_monitoring_dashboards \
              --network monitoring --name grafana -p 3000:3000 \
              -e GF_SECURITY_ALLOW_EMBEDDING=true \
              -e GF_AUTH_ANONYMOUS_ENABLED=true \
              -e GF_AUTH_ANONYMOUS_ORG_NAME=anonymous_org \
              -e GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer grafana/grafana:6.3.6
EOF

    user-data = <<EOF
#cloud-config

users:
  - name: mqttd
    groups: docker
write_files:
  - path: /tmp/sample_file
    permissions: 0644
    owner: root
    content: |
      sample content
runcmd:
  - mkdir /var/mqttd_monitoring
  - cd /var/mqttd_monitoring
  - echo cluster ${var.cluster_name} >> start.log
  - echo scripts download start >> start.log
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/prometheus-yaml", -H, "Metadata-Flavor: Google", -o, prometheus.yaml]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/run-grafana-sh", -H, "Metadata-Flavor: Google", -o, runGrafana.sh]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/grafana-prometheus-datasource-yaml", -H, "Metadata-Flavor: Google", -o, datasource.yaml]
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/grafana-dashboard-provider-yaml", -H, "Metadata-Flavor: Google", -o, dashboard-provider.yaml]
  - mkdir dashboards
  - [curl, "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mqttd-grafana-dashboard-json", -H, "Metadata-Flavor: Google", -o, dashboards/mqttd-grafana-dashboard.json]
  - echo starting prometheus >> start.log
  - docker network create monitoring
  - docker run -d -v /var/mqttd_monitoring/prometheus.yaml:/etc/prometheus/prometheus.yaml --network monitoring -p 9090:9090 --name prometheus prom/prometheus:v2.16.0 --config.file=/etc/prometheus/prometheus.yaml --web.listen-address 0.0.0.0:9090
  - echo starting grafana >> start.log
  - chmod a+x runGrafana.sh
  - sh runGrafana.sh
  - echo init done >>  start.log

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
}


resource "google_compute_target_pool" "mqttd" {
  name = "instance-pool"

  health_checks = [
    google_compute_http_health_check.mqttd_monitoring.name,
  ]
}

resource "google_compute_http_health_check" "mqttd_monitoring" {
  name = "mqttd-monitoring-check"
  port = 1884
  request_path = "/metrics"
  check_interval_sec = 15
  timeout_sec = 15
}

resource "google_compute_instance_group_manager" "mqttd_group" {
  name = "mqttd-igm"

  base_instance_name = "mqttd"
  zone = var.zone

  depends_on = [google_compute_router_nat.nat]

  version {
    instance_template = google_compute_instance_template.mqttd.self_link
  }

  target_pools = [
    google_compute_target_pool.mqttd.self_link]
  target_size = var.waterstream_replicas_count
  wait_for_instances = true

  named_port {
    name = "mqtt"
    port = 1883
  }

  named_port {
    name = "monitoring"
    port = 1884
  }

//    auto_healing_policies {
//      health_check = google_compute_http_health_check.mqttd_monitoring.self_link
//      initial_delay_sec = 300
//    }
}

resource "google_compute_instance_from_template" "mqttd_monitoring" {
  name = "mqttd-monitoring"
  zone = var.zone
  depends_on = [
    google_compute_instance_group_manager.mqttd_group
  ]
  source_instance_template = google_compute_instance_template.mqttd-monitoring.self_link
}

