output "aws_region" {
  value       = var.aws_region
  description = "Región AWS usada por el despliegue"
}

output "s3_bucket" {
  value       = var.s3_bucket
  description = "Nombre del bucket S3"
}
output "dynamodb_table_name" {
  value       = module.dynamodb_table.dynamodb_table_id
  description = "Nombre de la tabla DynamoDB para el bloqueo del estado de Terraform"
}