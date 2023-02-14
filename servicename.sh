#!/bin/bash
cluster="mb-stage-private"
profile="medibuddy"
region="ap-south-1"
#service="trino-coordinator"
service_name=$(aws ecs list-services --cluster $cluster  --region $region --profile $profile --query "serviceArns")
#service=$(aws ecs list-services --cluster $cluster  --region $region --profile $profile --query "serviceArns" | sed 's:.*/::' | tr -d "[]\","| sed '/^[[:space:]]*$/d')

#for i in $service
#do 
#DC=$(aws ecs describe-services --services $service --profile $profile --cluster $cluster --region $region |  jq -r '.services[].desiredCount')
#done
#echo $DC
#jq -n --arg DesiredCount "$DC" '{$DesiredCount}'
echo $service_name | jq -c --arg service_name "$service_name" '{$service_name}'
#echo $service_name | jq -c --arg service_name {"DesiredCount":$service_name}'
