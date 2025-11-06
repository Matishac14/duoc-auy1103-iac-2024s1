# s3-backend-bootstrap

Propósito
- Crear un bucket S3 y una tabla DynamoDB para almacenar el estado remoto de Terraform y el bloqueo (state + locking).

Requisitos
- Credenciales AWS configuradas (env vars, `~/.aws/credentials` o profile).
- Terraform >= 1.0.
- Variable obligatoria: `s3_bucket` (nombre del bucket a crear).

Variables principales
- `s3_bucket` \- nombre del bucket S3 que contendrá el state.
- (Opcional) `aws_region` \- región donde crear recursos.

Comandos para validar
1. Ir al directorio:
    - `cd act-formativa/s3-backend-bootstrap`
2. Inicializar:
    - `terraform init`
3. Ver cambios:
    - `terraform plan -var="s3_bucket=mi-bucket"`
4. Aplicar:
    - `terraform apply -var="s3_bucket=mi-bucket"`
5. Verificar:
    - Confirmar que existe el bucket S3 y la tabla DynamoDB `terraform-tcf-lock` en la consola AWS.

Ejemplo de backend S3 para otros proyectos
\`\`\`hcl
terraform {
backend "s3" {
bucket         = "mi-bucket"
key            = "the-cheesee-factory/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-tcf-lock"
encrypt        = true
}
}
\`\`\`

Notas
- Si usas `terraform.tfvars`, no es necesario pasar `-var` en la línea de comandos.
- Para borrar los recursos: `terraform destroy -var="s3_bucket=mi-bucket"`.
