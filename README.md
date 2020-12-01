Waterstream GCP Compute Engine setup with Confluent Cloud
=========================================================

## Pre-requisites

  - GCP account
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
    
TODO: describe 
   
Put Waterstream license file into the project root as `waterstream.license`.

Prepare Terraform plugins:
```shell script
terraform init

```
    
## Deploy

```shell script
./apply.sh
```

It applies terraform resources in 2 steps - this is needed for proper initialization of monitoring

Output contains URLs for MQTT load balancer and Grafana console.

## Undeploy

```shell script 
./destroy.sh
```

