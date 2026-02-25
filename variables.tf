variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "table_bucket_name" {
  description = "Name of the S3 table bucket"
  type        = string
}

variable "namespaces" {
  description = "Map of namespaces (databases) to create"
  type        = map(object({}))
  default     = {}
}
