# Backend Bootstrap

Módulo de inicialización que provisiona el estado remoto de Terraform en AWS.

## 🏗️ Arquitectura tras Apply

```mermaid
graph TB
    AWS["☁️ AWS ACCOUNT <br/> Global"]
    
    AWS --> S3["📦 S3 Bucket"]
    AWS --> DDB["🔒 DynamoDB Table"]

    S3 --> S3_Name["Name: tu-bucket-unico"]
    S3 --> S3_Ver["✅ Versionado"]
    S3 --> S3_Enc["✅ Cifrado AES-256"]
    S3 --> S3_Block["✅ Acceso Público Bloqueado"]
    S3 --> S3_Content["Contenido: <br/> terraform.tfstate"]

    DDB --> DDB_Name["Name: terraform-tcf-lock"]
    DDB --> DDB_Bill["Billing: PAY_PER_REQUEST"]
    DDB --> DDB_Key["Hash Key: LockID"]
    DDB --> DDB_Func["Funciones: <br/> Bloqueos distribuidos"]

    %% Corrección de sintaxis aquí
    S3_Ver -. "Conectado con" .-> DDB_Name

    style AWS fill:#E8F5E9
    style S3 fill:#FFF3E0
    style DDB fill:#FCE4EC
    style S3_Content fill:#FFFDE7
    style DDB_Func fill:#F3E5F5
```

### Flujo de Funcionamiento
```mermaid
graph LR
TF["💻 Terraform"]

    TF -->|"1. terraform init"| Init["Detectar backend"]
    Init -->|"2. Conectar"| Connect["Conectar a S3"]
    
    Connect -->|"3. Leer state"| S3["📦 S3 Bucket"]
    S3 -->|"4. Bloquear"| DDB["🔒 DynamoDB<br/>LockID"]
    
    DDB -->|"5. Bloqueo adquirido"| Plan["6. terraform plan<br/>terraform apply"]
    
    Plan -->|"7. Cambios"| Write["Escribir nuevo state"]
    Write -->|"8. Guardar"| S3
    
    S3 -->|"9. Versionar"| Ver["Mantener histórico"]
    Ver -->|"10. Liberar lock"| DDB
    
    DDB -->|"11. Completado"| Done["✅ Operación exitosa"]
    
    style S3 fill:#FF9800,stroke:#333,stroke-width:2px
    style DDB fill:#FF5722,stroke:#333,stroke-width:2px
    style Done fill:#4CAF50,stroke:#333,stroke-width:2px
```
## 📋 Descripción

Este módulo crea la infraestructura necesaria para almacenar y gestionar el estado de Terraform de forma centralizada y segura:

- **Bucket S3**: Almacenamiento centralizado del archivo `terraform.tfstate`
- **Tabla DynamoDB**: Control de bloqueos distribuidos para evitar cambios concurrentes
- **Versionado**: Habilitado en S3 para recuperación de estados anteriores
- **Cifrado**: AES-256 en el bucket S3

## 🔐 Características de Seguridad

- ✅ Bloqueo de acceso público al bucket S3
- ✅ Cifrado del estado de Terraform (AES-256)
- ✅ Versionado habilitado para auditoría
- ✅ Control de bloqueos con DynamoDB
- ✅ Políticas de acceso restrictivas

## 📋 Requisitos Previos

- AWS CLI configurado con credenciales válidas
- Terraform >= 1.0
- Permisos en AWS para crear:
  - Buckets S3
  - Tablas DynamoDB
  - Políticas IAM

## 🚀 Guía de Despliegue

### Paso 1: Preparar Variables

Copia el archivo de ejemplo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` y configura tu nombre de bucket único:

```hcl
s3_bucket = "mi-nombre-unico-bucket-tcf-2026"
aws_region = "us-east-1"
```

### Paso 2: Inicializar Terraform

```bash
terraform init
```

### Paso 3: Revisar el Plan

```bash
terraform plan -var-file="terraform.tfvars"
```

### Paso 4: Aplicar la Configuración

```bash
terraform apply -var-file="terraform.tfvars"
```

### Paso 5: Verificar Recursos Creados

En AWS Console:
- S3: Confirma que el bucket existe y tiene versionado habilitado
- DynamoDB: Verifica que la tabla `terraform-tcf-lock` existe

## 📝 Variables de Configuración

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `s3_bucket` | string | — | Nombre único del bucket S3 (obligatorio) |
| `aws_region` | string | us-east-1 | Región AWS donde crear recursos |

### ⚠️ Notas sobre Variables

- **s3_bucket**: Debe ser globalmente único en toda AWS
  - Ejemplo: `empresa-tcf-bucket-20260501`
  - Sugerencia: Incluye fecha o ID único para garantizar unicidad
  
- **aws_region**: Usa la región más cercana a tu ubicación
  - Regiones recomendadas: us-east-1, eu-west-1, us-west-2

## 📊 Outputs

Después de aplicar, Terraform generará estos outputs:

```bash
terraform output
```

- `s3_bucket_name`: Nombre del bucket S3 creado
- `s3_bucket_arn`: ARN del bucket
- `dynamodb_table_name`: Nombre de la tabla DynamoDB
- `dynamodb_table_arn`: ARN de la tabla
- `dynamodb_ttl_attribute`: Atributo TTL configurado

### Diagrama: Relación Outputs-Recursos

```mermaid
graph TB
    Outputs["📤 TERRAFORM OUTPUTS"]
    
    Outputs --> S3_Out["📦 S3 Bucket Outputs"]
    Outputs --> DDB_Out["🔒 DynamoDB Outputs"]
    
    S3_Out --> S3_Name["s3_bucket_name<br/>tu-nombre-bucket-unico<br/>Uso: Referencia bucket"]
    S3_Out --> S3_ARN["s3_bucket_arn<br/>arn:aws:s3:::...<br/>Uso: Políticas IAM"]
    S3_Out --> S3_Props["Propiedades:<br/>✅ Versionado: ON<br/>✅ Cifrado: AES-256<br/>✅ Público: BLOQUEADO"]
    
    DDB_Out --> DDB_Name["dynamodb_table_name<br/>terraform-tcf-lock<br/>Uso: Referencia tabla"]
    DDB_Out --> DDB_ARN["dynamodb_table_arn<br/>arn:aws:dynamodb:...<br/>Uso: Políticas IAM"]
    DDB_Out --> DDB_TTL["dynamodb_ttl_attribute<br/>LockExpireTime<br/>Uso: Auto-cleanup"]
    DDB_Out --> DDB_Props["Propiedades:<br/>✅ Billing: PAY_PER_REQUEST<br/>✅ Hash Key: LockID<br/>✅ Locking: ACTIVO"]
    
    S3_Out --> Usage["Usar en: autre módulos<br/>Configurar backend en<br/>infra/app/providers.tf"]
    DDB_Out --> Usage
    
    style Outputs fill:#E3F2FD
    style S3_Out fill:#FFF3E0
    style DDB_Out fill:#FCE4EC
    style S3_Props fill:#FFFDE7
    style DDB_Props fill:#F3E5F5
    style Usage fill:#C8E6C9
```

## 🔗 Configurar Otros Módulos

Una vez creado el backend remoto, configura otros proyectos Terraform para usarlo.

### En `infra/app/providers.tf`

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mi-nombre-unico-bucket-tcf-2026"
    key            = "cheese-factory/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-tcf-lock"
    encrypt        = true
  }
}
```

## 🔄 Operaciones Comunes

### Listar Recursos Creados

```bash
terraform state list
terraform state show aws_s3_bucket.state_bucket
terraform state show aws_dynamodb_table.terraform_lock
```

### Renovar Configuración

Si necesitas cambiar valores:

```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Destruir la Infraestructura

⚠️ **ADVERTENCIA**: Esto eliminará el bucket S3 y perderá el estado de Terraform.

```bash
# Solo si estás seguro y ya migraste cualquier estado importante
terraform destroy -var-file="terraform.tfvars"
```

## 📚 Archivos del Módulo

| Archivo | Descripción |
|---------|-------------|
| `main.tf` | Configuración principal (S3, DynamoDB) |
| `variables.tf` | Definición de variables de entrada |
| `outputs.tf` | Outputs exportados |
| `providers.tf` | Configuración de AWS provider |
| `terraform.tfvars.example` | Ejemplo de archivo de variables |

## 🛠️ Troubleshooting

### Error: "Bucket already exists"

El nombre del bucket S3 ya está en uso. Los nombres deben ser:
- Globalmente únicos
- Entre 3 y 63 caracteres
- Solo letras minúsculas, números y guiones

**Solución**: Usa un nombre diferente en `s3_bucket`

### Error: "Access Denied" en DynamoDB

Verifica que tu usuario AWS tiene permisos:
- `dynamodb:CreateTable`
- `dynamodb:DescribeTable`
- `s3:CreateBucket`
- `s3:PutBucketVersioning`

### Acceso remoto no funciona

Verifica que en otros módulos está correctamente configurado:

```bash
terraform init -reconfigure
```

## 📖 Documentación Relacionada

- [Documentación Principal](../../docs/README.md)
- [Módulo App](../app/README.md)
- [AWS Terraform Backend Documentation](https://www.terraform.io/language/settings/backends/s3)

---

## 📊 Diagrama: Interacción Backend S3+DynamoDB

```mermaid
sequenceDiagram
    participant Local as 💻 Máquina Local
    participant AWS as ☁️ AWS
    participant IAM as 🔐 IAM
    participant DDB as 🔒 DynamoDB
    participant S3 as 📦 S3 Bucket
    
    Local->>AWS: terraform init/apply
    AWS->>IAM: Autenticar credenciales
    IAM-->>AWS: ✅ Credenciales válidas
    
    AWS->>DDB: ACQUIRE LOCK
    DDB-->>AWS: LockID registrado<br/>Estado: LOCKED ✅
    
    AWS->>S3: Leer estado actual
    S3-->>AWS: terraform.tfstate
    
    AWS->>AWS: Ejecutar terraform plan/apply<br/>Generar cambios
    
    AWS->>S3: Escribir nuevo estado
    S3->>S3: Versionar archivo anterior
    S3-->>AWS: ✅ Estado guardado
    
    AWS->>DDB: RELEASE LOCK
    DDB-->>AWS: Lock eliminado<br/>Estado: UNLOCKED ✅
    
    AWS-->>Local: ✅ Operación completada
```

---

## 🔐 Seguridad: Cifrado y Acceso

```mermaid
graph TB
    Physical["🏢 Acceso Físico<br/>AWS Data Centers<br/>Multi-region redundancy"]
    
    AtRest["🔐 Cifrado en Reposo"]
    AtRest_S3["S3: AES-256<br/>Server-Side Encryption"]
    AtRest_DDB["DynamoDB: Encryption at rest<br/>Habilitado por defecto"]
    
    InTransit["🔒 Cifrado en Tránsito<br/>TLS 1.2+<br/>HTTPS"]
    
    IAM["🔑 Control de Acceso IAM"]
    IAM_Auth["Solo usuario/role autenticado"]
    IAM_Policies["Políticas de bucket restrictivas"]
    
    Audit["📋 Auditoría y Versionado"]
    Audit_Ver["S3 Versioning:<br/>Historial completo"]
    Audit_Log["Access Logging:<br/>Quién accedió cuándo"]
    Audit_Trail["CloudTrail:<br/>Auditoría de API calls"]
    
    Physical --> AtRest
    AtRest --> AtRest_S3
    AtRest --> AtRest_DDB
    
    Physical --> InTransit
    
    Physical --> IAM
    IAM --> IAM_Auth
    IAM --> IAM_Policies
    
    Physical --> Audit
    Audit --> Audit_Ver
    Audit --> Audit_Log
    Audit --> Audit_Trail
    
    style Physical fill:#C8E6C9
    style AtRest fill:#BBDEFB
    style InTransit fill:#FFF9C4
    style IAM fill:#FFE0B2
    style Audit fill:#F8BBD0
```

---

## 📋 Documentación Relacionada
