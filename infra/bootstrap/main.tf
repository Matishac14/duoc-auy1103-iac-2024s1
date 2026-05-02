# Módulo para el Bucket S3 del Estado de Terraform
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = var.s3_bucket

  # Seguridad: Acceso Privado
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  acl                      = "private"

  # Seguridad: Bloqueo de Acceso Público (Zero Trust)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Seguridad: Cifrado en Reposo
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Fiabilidad: Versionado para recuperación de desastres
  versioning = {
    enabled = true
  }

  tags = {
    Name        = "Terraform State Backend"
    Project     = "The Cheese Factory"
    Environment = "Global"
  }
}

# Módulo para la Tabla DynamoDB (Locking)
module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.0"

  name         = "terraform-tcf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Name        = "Terraform State Lock Table"
    Project     = "The Cheese Factory"
    Environment = "Global"
  }
}