provider "aws" {
  region                   = var.region
  shared_credentials_files = ["/Users/mounikabethu/.aws/credentials"]
  profile                  = "medibuddy"
}
################################################################################
########### creating autoscaling for services ##################################
##################################################################################
resource "aws_appautoscaling_target" "service-autoscale" {
  for_each           = data.aws_ecs_service.service
  service_namespace  = "ecs"
  resource_id        = split(":", each.value.arn)[5]
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs-autoscale-role.arn
  min_capacity       =  each.value.desired_count
  max_capacity       =  each.value.desired_count*2
}
################################################################################
########### fetching the servicename from shellscript ################################
##################################################################################

data "external" "example" {
  program = ["bash","servicename.sh"]
  }
################################################################################
######################## ecsservice datablock ######################################
##################################################################################

data "aws_ecs_service" "service" {
  for_each           = toset(flatten([for k, v in data.external.example.result : jsondecode(v)]))
  service_name       = each.value
  cluster_arn        = "arn:aws:ecs:ap-south-1:247653494814:cluster/${var.cluster_name}"
}
################################################################################
######################## cpu-scale-up-policy ######################################
############################################################################
resource "aws_appautoscaling_policy" "target-cpu-scaleup_policy" {
  #for_each           = toset(flatten([for k, v in data.external.example.result : jsondecode(v)]))
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-cpu_scaleup"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
  #depends_on = [aws_appautoscaling_target.service-autoscale]
}

################################################################################
######################## memory-scale-up-policy ######################################
############################################################################
resource "aws_appautoscaling_policy" "target-memory-scaleup_policy" {
  #for_each           = toset(flatten([for k, v in data.external.example.result : jsondecode(v)]))
  for_each           = data.aws_ecs_service.service
  name               = "${each.value.service_name}-memory_scaleup"
  policy_type        = "TargetTrackingScaling"
  resource_id        = split(":", each.value.arn)[5]
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
    target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 50
  }
  #depends_on = [aws_appautoscaling_target.service-autoscale]
}

# CLOUDWATCH ALARM to monitor the cpu utilization of a service (creating alarams)
  resource "aws_cloudwatch_metric_alarm" "target-cpu-scaleup-alaram" {
  for_each           = data.aws_ecs_service.service
    #count             = length(var.servicename) > 0 ? 1 : 0
  #alarm_description = "Scale up alarm for ${each.value.service}"
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.service_name}-cpu-scaleup-alaram"
  alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:AWS_SERVICES_METRICS"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "60"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  period              = "120"
  statistic           = "Maximum"
  datapoints_to_alarm =  "2"
  dimensions = {
    #count       = length(var.servicename)
    ClusterName = "${var.cluster_name}"
    ServiceName = "${each.value.service_name}"
  }
  
}

# CLOUDWATCH ALARM to monitor the memory utilization of a service (creating alarams)
  resource "aws_cloudwatch_metric_alarm" "target-memory-scaleup-alaram" {
  for_each           = data.aws_ecs_service.service
    #count             = length(var.servicename) > 0 ? 1 : 0
  #alarm_description = "Scale up alarm for ${each.value.service}"
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.service_name}-memory-scaleup-alaram"
  alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:AWS_SERVICES_METRICS"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "60"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  period              = "120"
  statistic           = "Maximum"
  datapoints_to_alarm =  "2"
  dimensions = {
    #count       = length(var.servicename)
    ClusterName = "${var.cluster_name}"
    ServiceName = "${each.value.service_name}"
  }
  
}





