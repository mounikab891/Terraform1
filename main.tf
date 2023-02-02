provider "aws" {
  region                    = var.region
  shared_credentials_files  = ["/Users/mounikabethu/.aws/credentials"]
  profile                   = "medibuddy"
}

resource "aws_appautoscaling_target" "stg-websiteapp" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/stg-ecs-cluster/stg-websiteapp"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.ecs-autoscale-role.arn
}
#######cpu######
resource "aws_appautoscaling_policy" "stg-websiteapp_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.stg-websiteapp.resource_id
  scalable_dimension = aws_appautoscaling_target.stg-websiteapp.scalable_dimension
  service_namespace  = aws_appautoscaling_target.stg-websiteapp.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
  depends_on = [aws_appautoscaling_target.stg-websiteapp]
  
}



###memory#####
resource "aws_appautoscaling_policy" "stg-websiteapp_memory" {
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.stg-websiteapp.resource_id
  scalable_dimension = aws_appautoscaling_target.stg-websiteapp.scalable_dimension
  service_namespace  = aws_appautoscaling_target.stg-websiteapp.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 60
  }
  depends_on = [aws_appautoscaling_target.stg-websiteapp]
   
}
# CLOUDWATCH ALARM to monitor the cpu utilization of a service (creating alarams)
  resource "aws_cloudwatch_metric_alarm" "stg-websiteapp-cpuUtilization" {
  #count             = length(var.autoscale) > 0 ? 1 : 0
  alarm_description = "Scale down alarm for ${var.name}"
  namespace         = "AWS/ECS"
  alarm_name        = "ecsautoscalingcputest"
  #alarm_actions     = [aws_appautoscaling_policy.stg-websiteapp.arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  period              = "120"
  statistic           = "Maximum"
  datapoints_to_alarm =  "2"

  dimensions = {
    ClusterName = "stg-ecs-cluster"
    ServiceName = "stg-websiteapp"
  }
}

# CLOUDWATCH ALARM to monitor the memory utilization of a service ( creating alarams)
  resource "aws_cloudwatch_metric_alarm" "stg-websiteapp-MemoryUtilization" {
  #count             = length(var.autoscale) > 0 ? 1 : 0
  alarm_description = "Scale down alarm for ${var.name}"
  namespace         = "AWS/ECS"
  alarm_name        = "ecsautoscaling_memoty_test"
  #alarm_actions     = [aws_appautoscaling_policy.stg-websiteapp.arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  period              = "120"
  statistic           = "Maximum"
  datapoints_to_alarm =  "2"

  dimensions = {
    ClusterName = "stg-ecs-cluster"
    ServiceName = "stg-websiteapp"
  }
}
