#!/bin/sh
set -e

#echo Desctorying MQTTD Group Manager
#terraform destroy -target google_compute_instance_group_manager.mqttd_group --auto-approve && true
#terraform destroy -target google_compute_target_pool.mqttd --auto-approve && true
#terraform destroy -target google_compute_instance_template.mqttd --auto-approve && true
#terraform destroy -target google_compute_network.net --auto-approve && true

echo Destroying MQTTD deploy
terraform destroy --auto-approve

date
