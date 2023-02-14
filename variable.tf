variable "region" {
  default     = "ap-south-1"
  type        = string
  description = "The region you want to deploy the infrastructure in"
}


#variable "servicename" {
#type = list(string)
#default = test
#}
variable "filename" {
  default = "datasets.csv"
}
#variable "servicename" {
  #type = list(string)
  #default = ["mb-meds-stage", "mb-medsff-stage"]
#}



variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster where service is to be autoscaled"
  default     = "mb-stage-private"
}

