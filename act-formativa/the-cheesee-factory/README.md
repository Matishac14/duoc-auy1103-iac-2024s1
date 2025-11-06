# the-cheesee-factory

Propósito
- Deploy de la infraestructura de la aplicación (VPC, subnets, security groups, EC2, etc.) usando módulos públicos Terraform.

Requisitos
- Backend S3 + DynamoDB creado (ver `act-formativa/s3-backend-bootstrap`) o uso local para pruebas.
- Credenciales AWS configuradas.
- Variables: `aws_region`, otras definidas en `variables.tf` o `terraform.tfvars`.

Correcciones comunes (ya aplicadas o a verificar)
- Asegurarse de tener el data source de AZs:
  \`\`\`hcl
  data "aws_availability_zones" "available" {
  state = "available"
  }
  \`\`\`
- En el módulo de security group usar `ingress_with_cidr_blocks` con `cidr_blocks` como lista. Ejemplo mínimo:
  \`\`\`hcl
  ingress_with_cidr_blocks = [
  {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  description = "HTTP access"
  cidr_blocks = ["0.0.0.0/0"]
  },
  {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  description = "SSH access"
  cidr_blocks = ["0.0.0.0/0"]
  },
  ]
  \`\`\`

Comandos para validar
1. Ir al directorio:
    - `cd act-formativa/the-cheesee-factory`
2. Inicializar (si cambias backend usa `-reconfigure`):
    - `terraform init`
3. Planificar:
    - `terraform plan -var-file="terraform.tfvars"`
4. Aplicar:
    - `terraform apply -var-file="terraform.tfvars"`
5. Verificar:
    - Comprobar recursos en la consola AWS (VPC, SG, EC2, etc.).

Notas
- Si apuntas a un backend S3 recién creado, usar `terraform init -reconfigure` y confirmar la configuración del `bucket`, `key` y `dynamodb_table`.
- Añadir/ajustar variables en `terraform.tfvars` para evitar pasar `-var` en cada comando.
