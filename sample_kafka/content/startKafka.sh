#!/bin/sh

set -e
SCRIPT_DIR=`realpath $(dirname "$0")`

PUBLIC_IP=$1

NETWORK_NAME=waterstream-demo
#CONFLUENT_VERSION=4.0.1
#CONFLUENT_VERSION=7.0.1

. $SCRIPT_DIR/config.sh
. $SCRIPT_DIR/tfConfig.sh

echo Creating network $NETWORK_NAME

docker network create $NETWORK_NAME || true

echo Starting ZooKeeper

docker run -d \
     -e ZOOKEEPER_CLIENT_PORT=2181 \
     -e ZOOKEEPER_TICK_TIME=2000 \
     --network $NETWORK_NAME \
     -p 2181:2181 \
     --restart unless-stopped \
     --name wsdemo-zookeeper confluentinc/cp-zookeeper:$CONFLUENT_VERSION

echo Waiting for ZooKeeper

#TODO avoid indefinite waiting
until echo ruok | nc localhost 2181 -v -w 5; do
  echo ZK not available yet
  sleep 3
done

echo Starting Kafka with external IP =$PUBLIC_IP

docker run -d \
     -e ZOOKEEPER_TICK_TIME=2000 \
     -e KAFKA_BROKER_ID=1 \
     -e KAFKA_ZOOKEEPER_CONNECT="wsdemo-zookeeper:2181" \
     -e KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://$PUBLIC_IP:9092" \
     -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
     -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
     -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \
     -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=false \
     --network $NETWORK_NAME \
     -p 9092:9092 \
     --restart unless-stopped \
     --name wsdemo-kafka confluentinc/cp-kafka:$CONFLUENT_VERSION

echo Waiting for Kafka start

docker exec wsdemo-kafka cub kafka-ready -b wsdemo-kafka:9092 1 60

echo Kafka start complete

