Waterstream GCP Compute Engine setup with Confluent Cloud
=========================================================

These scripts deploy Waterstream MQTT Broker (https://docs.waterstream.io/release/index.html)
on GCP using Google Compute Instances and a Docker image (that is, without GKE - because such setup supports larger number of connections per node),
while using Confluent Cloud as the Kafka provider. Includes Prometheus+Grafana monitoring of Waterstream.

## Pre-requisites

  - GCP account (https://console.cloud.google.com/)
  - Confluent Cloud account (https://confluent.cloud/)
  - Terraform installed locally
  - Waterstream license file
  
## Create Kafka topics

You'll need Confluent Cloud CLI: https://docs.confluent.io/current/cloud/cli/install.html
After installation log into the cloud:
```shell script
ccloud login
```

And run the topic creation script with your cluster ID (not to mix up with cluster name!):
```shell script
./createTopicsCCloudMinimal.sh <cluster_ID> 
````

## Configure 
  
### License

Put Waterstream license file into the project root as `waterstream.license`.

### GCP Authentication

Ensure account.json is in this folder. 
You will have to [create a service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) on GCP first. 
Choose the right roles and enable google API. If something is missing terraform let you know.
Some of the roles you may need: `roles/compute.viewer`, `roles/iam.serviceAccountAdmin`, `roles/storage.admin`, `roles/iam.serviceAccountKeyAdmin`.

### Waterstream parameters

Copy the variables file from the example: 

```shell script
cp config-examples/config.auto.tfvars.example config.auto.tfvars

```

Edit this file, see the comments for the parameter explanation. 
The mandatory parameters to specify are:
- `project`, `region`, `zone` to indicate where in GCP to deploy,
- `bootstrap_server`, `ccloud_api_key`, `ccloud_api_secret` to specify how to connect to Confluent Cloud Kafka cluster,
- `waterstream_replicas_count` - how many Waterstream instances to run 

### Terraform initialization

Prepare Terraform plugins:
```shell script
terraform init

```
    
## Deploy

```shell script
./apply.sh
```

It applies terraform resources in 2 steps - this is needed for the proper initialization of monitoring

Output contains URLs for MQTT load balancer and Grafana console.

## Undeploy

```shell script 
./destroy.sh
./deleteTopicsCCloud.sh
```

