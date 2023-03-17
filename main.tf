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
  #role_arn           = aws_iam_role.ecs-autoscale-role.arn
  min_capacity       =  each.value.desired_count
  max_capacity       =  each.value.desired_count*2
}
################################################################################
########### fetching the servicename from shellscript ################################
##################################################################################

data "external" "example" {
  program = ["bash","servicename.sh","${var.cluster_name}"]
  }
################################################################################
######################## ecsservice datablock ######################################
##################################################################################

data "aws_ecs_service" "service" {
  for_each           = toset(flatten([for k, v in data.external.example.result : jsondecode(v)]))
  service_name       = each.value
  cluster_arn        = "arn:aws:ecs:ap-south-1:247653494814:cluster/${var.cluster_name}"
}

##########################################################################################
##########CLOUDWATCH ALARM to monitor the cpu-scaleup utilization of a service (creating alarams)################################
########################################################################################
  resource "aws_cloudwatch_metric_alarm" "target-cpu-scaleup-alaram" {
  for_each           = aws_appautoscaling_policy.target-cpu-scaleup_policy
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.name}"
  #alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "80"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  period              = "1800"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.cluster_name}"
    ServiceName = "${split("/", each.value.resource_id)[2]}"
  }
  alarm_description = "This metric monitors AWS/ECS/SERVICE CPU utilization"
  alarm_actions     = ["${each.value.arn}","arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]

}

#########################################################################################
##########CLOUDWATCH ALARM to monitor the cpu-scaledown utilization of a service (creating alarams)################################
########################################################################################
  resource "aws_cloudwatch_metric_alarm" "target-cpu-scaledown-alaram" {
  for_each           = aws_appautoscaling_policy.target-cpu-scaledown_policy
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.name}"
  #alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "30"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  period              = "1800"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.cluster_name}"
    ServiceName = "${split("/", each.value.resource_id)[2]}"
  }
  alarm_description = "This metric monitors AWS/ECS/SERVICE CPU utilization"
  alarm_actions     = ["${each.value.arn}","arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]

}

######################################################################################
##CLOUDWATCH ALARM to monitor the memory-scaleup utilization of a service (creating alarams)##########
#########################################################################################
  resource "aws_cloudwatch_metric_alarm" "target-memory-scaleup-alaram" {
  for_each           = aws_appautoscaling_policy.target-memory-scaleup_policy
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.name}"
  #alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "80"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  period              = "1800"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.cluster_name}"
    ServiceName = "${split("/", each.value.resource_id)[2]}"
  }
  alarm_description = "This metric monitors AWS/ECS/SERVICE Memory utilization"
  alarm_actions     = ["${each.value.arn}", "arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
}

####################################################################################
##CLOUDWATCH ALARM to monitor the memory-scaledown utilization of a service (creating alarams)##########
#########################################################################################
  resource "aws_cloudwatch_metric_alarm" "target-memory-scaledown-alaram" {
  for_each           = aws_appautoscaling_policy.target-memory-scaledown_policy
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.name}"
  #alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "30"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  period              = "1800"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.cluster_name}"
    ServiceName = "${split("/", each.value.resource_id)[2]}"
  }
  alarm_description = "This metric monitors AWS/ECS/SERVICE Memory utilization"
  alarm_actions     = ["${each.value.arn}", "arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
}
################################################################################
######################## cpu-scale-up-policy ######################################
##################################################################################
resource "aws_appautoscaling_policy" "target-cpu-scaleup_policy" {
  #count              = length(var.target-cpu-scaleup_policy)
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-cpu_scaleup"
  policy_type        = "StepScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    
    step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
      
    }
    
  }
 
}
################################################################################
######################## cpu-scale-down-policy ######################################
##################################################################################
resource "aws_appautoscaling_policy" "target-cpu-scaledown_policy" {
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-cpu_scaledown"
  policy_type        = "StepScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    
    step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
      
    }
    
  }
 
}


################################################################################
######################## memory-scale-up-policy ######################################
################################################################################
resource "aws_appautoscaling_policy" "target-memory-scaleup_policy" {
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-memory_scaleup"
  policy_type        = "StepScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
      }
  }

  
}

###############################################################################
######################## memory-scale-down-policy ######################################
##################################################################################
resource "aws_appautoscaling_policy" "target-memory-scaledown_policy" {
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-memory_scaledown"
  policy_type        = "StepScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    
    step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
      
    }
    
  }
 
}



