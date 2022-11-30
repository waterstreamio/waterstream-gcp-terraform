#!/bin/sh

echo Setting up Kafka topics

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

. $SCRIPT_DIR/config.sh

#30 days
#DEFAULT_MESSAGES_RETENTION=2592000000
#7 days
#DEFAULT_MESSAGES_RETENTION=604800000
#1 day
DEFAULT_MESSAGES_RETENTION=86400000

HEARTBEAT_TOPIC=__waterstream_heartbeat
docker exec wsdemo-kafka kafka-topics --bootstrap-server wsdemo-kafka:9092 --create --if-not-exists --topic ${SESSION_TOPIC} --partitions 5 --replication-factor 1 --config cleanup.policy=compact --config min.compaction.lag.ms=60000 --config delete.retention.ms=600000
docker exec wsdemo-kafka kafka-topics --bootstrap-server wsdemo-kafka:9092 --create --if-not-exists --topic ${RETAINED_MESSAGES_TOPIC} --partitions 5 --replication-factor 1 --config cleanup.policy=compact --config min.compaction.lag.ms=60000 --config delete.retention.ms=600000
docker exec wsdemo-kafka kafka-topics --bootstrap-server wsdemo-kafka:9092 --create --if-not-exists --topic ${CONNECTION_TOPIC} --partitions 5 --replication-factor 1 --config cleanup.policy=delete --config retention.ms=600000 --config delete.retention.ms=3600000
docker exec wsdemo-kafka kafka-topics --bootstrap-server wsdemo-kafka:9092 --create --if-not-exists --topic ${KAFKA_MESSAGES_DEFAULT_TOPIC} --partitions ${KAFKA_MESSAGES_DEFAULT_TOPIC_PARTITIONS} --replication-factor 1 --config retention.ms=$DEFAULT_MESSAGES_RETENTION
docker exec wsdemo-kafka kafka-topics --bootstrap-server wsdemo-kafka:9092 --create --if-not-exists --topic ${HEARTBEAT_TOPIC} --partitions 5 --replication-factor 1 --config cleanup.policy=delete --config retention.ms=60000 --config delete.retention.ms=120000

echo Topics creation complete
