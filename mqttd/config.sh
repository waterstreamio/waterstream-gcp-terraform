#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

#Read Terraform-generated config
. $SCRIPT_DIR/tfConfig.sh

#Kafka config
#============
export KAFKA_BOOTSTRAP_SERVERS=pkc-4r297.europe-west1.gcp.confluent.cloud:9092
export KAFKA_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${CCLOUD_API_KEY}\" password=\"${CCLOUD_API_SECRET}\";"
export KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM="https"
export KAFKA_SASL_MECHANISM="PLAIN"
export KAFKA_SECURITY_PROTOCOL="SASL_SSL"
export KAFKA_REQUEST_TIMEOUT_MS=20000
export KAFKA_RETRY_BACKOFF_MS=500
#Empty to disable transactional messages - a bit less guarantees, but much faster. To enable transactions specify
# each instance must have its own stable value
export KAFKA_TRANSACTIONAL_ID=
#Default topic for messages - anything not matched by KAFKA_MESSAGES_TOPICS_PATTERNS goes here.
export KAFKA_MESSAGES_DEFAULT_TOPIC=mqtt_messages
#Additional topics for messages and respective MQTT topic patterns.
#Comma-separated: kafkaTopic1:pattern1,kafkaTopic2:pattern2. Patterns follow the MQTT subscription wildcards rules
export KAFKA_MESSAGES_TOPICS_PATTERNS="sensor-data:vehicles/sensor/data/#"
#Retained messages topic - for messages which should be delivered automatically on subscription. Should be compacted.
export RETAINED_MESSAGES_TOPIC=mqtt_retained_messages
#Session state persistence topic. Should be compacted
export SESSION_TOPIC=mqtt_sessions
#Connections topic - for detecting concurrent connections with same client ID.
export CONNECTION_TOPIC=mqtt_connections
export KAFKA_STREAMS_APPLICATION_NAME="waterstream-kafka"
export KAFKA_STREAMS_STATE_DIRECTORY="/tmp/kafka-streams"
#Should it clean the local state directory when MQTTd starts
export KAFKA_RESET_STREAMS_ON_START=false
#Should it clean the local state directory when MQTTd stops
export KAFKA_RESET_STREAMS_ON_EXIT=false
#Queue length for reading messages from Kafka
export CENTRALIZED_CONSUMER_LISTENER_QUEUE=32

#MQTT settings
#=============
export MQTT_PORT=1883
#Size of thread pool for blocking operations
export MQTT_BLOCKING_THREAD_POOL_SIZE=10
#Size of queue for receiving messages - between network event handling loop and actual processing of the messages
export MAX_QUEUED_INCOMMING_MESSAGES=1000
#Maximal number of in-flight messages per client - QoS 1 or QoS 2 messages which are in the middle of the communication sequence.
export MQTT_MAX_IN_FLIGHT_MESSAGES=10

#Monitoring
#==========
#Port to expose the metrics in Prometheus format
export MONITORING_PORT=1884
#Should the metrics output also include standard JVM metrics
export MONITORING_INCLUDE_JAVA_METRICS=true

#SSL
export SSL_ENABLED=false
#export SSL_KEY_PATH=
#export SSL_CERT_PATH=

#Authentication
#USERS_FILE_PATH=

#Kotlin coroutines thread pool size. Optimal coroutines threads  number is 2*CPU cores number
export COROUTINES_THREADS=8
#Custom log configuration file. At the moment doesn't apply to dockerized mqttd.
export LOGBACK_CONFIG=$SCRIPT_DIR/logbackCustom.xml



