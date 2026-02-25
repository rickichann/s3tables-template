output "table_bucket_arn" {
  description = "ARN of the S3 table bucket"
  value       = local.table_bucket_arn
}

output "namespaces" {
  description = "Created namespaces (databases)"
  value       = { for k, v in aws_s3tables_namespace.namespaces : k => v.namespace }
}

output "glue_databases" {
  description = "Created Glue databases for Athena"
  value       = { for k, v in aws_glue_catalog_database.databases : k => v.name }
}
