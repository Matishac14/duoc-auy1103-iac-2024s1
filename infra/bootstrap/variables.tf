variable "aws_region" {
  description = "Región de AWS para el despliegue del backend"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket" {
  description = "Nombre globalmente único para el bucket de estado de Terraform"
  type        = string
}