
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

################################################################################
######################## cpu-scale-up-policy ######################################
############################################################################
  
resource "aws_appautoscaling_policy" "target-cpu-scaleup_policy" {
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-cpu_scaleup"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    target_tracking_scaling_policy_configuration {
      target_value = 80
    customized_metric_specification {
      #for_each           = aws_appautoscaling_target.service-autoscale
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      statistic   = "Maximum"
      unit        = "Percent"
      dimensions {
        name  = "ClusterName"
        value = "${var.mb-privatecluster-2}"
      }
      dimensions {
        name  = "ServiceName"
        value = "${split("/", each.value.resource_id)[2]}"
      }
      
    }
    
  }
}
  

################################################################################
######################## memory-scale-up-policy ######################################
############################################################################
resource "aws_appautoscaling_policy" "target-memory-scaleup_policy" {
  for_each           = aws_appautoscaling_target.service-autoscale
  name               = "${split("/", each.value.resource_id)[2]}-memory_scaleup"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id 
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
    target_tracking_scaling_policy_configuration {
      target_value = 80
    customized_metric_specification {
      #for_each    = aws_appautoscaling_target.service-autoscale
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      statistic   = "Maximum"
      unit        = "Percent"
      dimensions {
        name  = "ClusterName"
        value = "${var.mb-privatecluster-2}"
      }

        dimensions {
        name  = "ServiceName"
        value = "${split("/", each.value.resource_id)[2]}"
      }
      }
  }

  
}

################################################################################
##########CLOUDWATCH ALARM to monitor the cpu utilization of a service (creating alarams)################################
############################################################################# 
  resource "aws_cloudwatch_metric_alarm" "target-cpu-scaleup-alaram" {
  for_each           = data.aws_ecs_service.service
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.service_name}-cpuUtilization"
  alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "80"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  period              = "360"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.mb-privatecluster-2}"
    ServiceName = "${each.value.service_name}"
  }
  
}
################################################################################
##CLOUDWATCH ALARM to monitor the memory utilization of a service (creating alarams)##########
############################################################################# 
  resource "aws_cloudwatch_metric_alarm" "target-memory-scaleup-alaram" {
  for_each           = data.aws_ecs_service.service
  namespace         = "AWS/ECS"
  alarm_name        = "${each.value.service_name}-memoryUtilization"
  alarm_actions     = ["arn:aws:sns:ap-south-1:247653494814:ecs-services-metrics"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "80"
  evaluation_periods  = "5"
  metric_name         = "MemoryUtilization"
  period              = "360"
  statistic           = "Maximum"
  datapoints_to_alarm =  "5"
  dimensions = {
    
    ClusterName = "${var.mb-privatecluster-2}"
    ServiceName = "${each.value.service_name}"
  }
  
}
