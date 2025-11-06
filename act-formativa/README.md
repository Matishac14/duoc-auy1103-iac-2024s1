# Proyecto: act-formativa

Resumen
- El repositorio contiene dos componentes principales:
    1. `act-formativa/s3-backend-bootstrap`: crea el bucket S3 y la tabla DynamoDB para el backend remoto de Terraform.
    2. `act-formativa/the-cheesee-factory`: despliega la infraestructura de la aplicación usando módulos Terraform y puede usar el backend creado.

Flujo recomendado
1. Provisionar backend remoto:
    - `cd act-formativa/s3-backend-bootstrap`
    - `terraform init`
    - `terraform apply -var="s3_bucket=mi-bucket"`
2. Configurar `the-cheesee-factory` para usar ese backend (colocar el bloque `backend "s3"` o usar `-backend-config`).
3. Desplegar la infraestructura de la aplicación:
    - `cd act-formativa/the-cheesee-factory`
    - `terraform init -reconfigure`
    - `terraform plan -var-file="terraform.tfvars"`
    - `terraform apply -var-file="terraform.tfvars"`

Buenas prácticas
- Mantener credenciales fuera del repo (usar profiles o variables de entorno).
- Usar nombres únicos para el `bucket` S3 (globalmente únicos).
- Probar primero con `terraform plan`.
- Para cambios en backend: usar `terraform init -reconfigure`.

Contacto
- Usuario GitHub: `Matishac14`
