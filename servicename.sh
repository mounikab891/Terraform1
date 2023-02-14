#!/bin/bash
cluster="$1"
profile="****"
region="*****"
#  getting list of services arn of cluster
service_name=$(aws ecs list-services --cluster $cluster  --region $region --profile $profile --query "serviceArns")

#storing output in json format in the variable 
echo $service_name | jq -c --arg service_name "$service_name" '{$service_name}'
