#!/bin/sh
set -e

echo Destroying MQTTD deploy
terraform destroy --auto-approve

date
