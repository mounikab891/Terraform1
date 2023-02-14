variable "region" {
  default     = "*********"
  type        = string
  description = "The region you want to deploy the infrastructure in"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster where service is to be autoscaled"
  default     = "******"
}

