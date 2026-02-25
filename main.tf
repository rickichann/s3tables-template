terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local variable for the table bucket ARN (bucket created via AWS CLI)
locals {
  table_bucket_arn = "arn:aws:s3tables:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bucket/${var.table_bucket_name}"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Namespaces (Databases)
resource "aws_s3tables_namespace" "namespaces" {
  for_each = var.namespaces

  namespace        = each.key
  table_bucket_arn = local.table_bucket_arn
}

# Glue Databases (for Athena integration)
resource "aws_glue_catalog_database" "databases" {
  for_each = var.namespaces

  name = each.key
}
