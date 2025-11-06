variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket" {
  description = "Nombre del bucket S3 para almacenar el estado de Terraform"
  type        = string
  default     = "my-unique-bucket-name-123456-mifz"
}