#!/bin/sh
set -e

echo Applying MQTTD group
terraform apply -target google_compute_instance_group_manager.mqttd_group --auto-approve

echo Applying remaining resources
terraform apply --auto-approve
