# AUY1103 - Infrastructure as Code

Repositorio de Infraestructura como Código para "The Cheese Factory", implementado utilizando Terraform en AWS.

## 📋 Descripción General

Este proyecto proporciona una solución completa de infraestructura en AWS, divide en dos componentes principales:

1. **Bootstrap** (`infra/bootstrap/`) - Estado remoto de Terraform
   - Provisiona un bucket S3 para almacenar el estado de Terraform
   - Configura una tabla DynamoDB para control de bloqueos distribuidos

2. **App** (`infra/app/`) - Infraestructura de aplicación
   - VPC con segmentación de red (subredes públicas y privadas)
   - Application Load Balancer (ALB) para distribución de tráfico
   - Instancias EC2 con integración Docker
   - Security Groups con modelo Zero Trust

## 🚀 Inicio Rápido

### Requisitos Previos

- AWS CLI configurado con credenciales válidas
- Terraform >= 1.0
- Acceso a AWS con permisos suficientes para crear recursos (S3, DynamoDB, VPC, EC2, ALB)

### Instalación y Despliegue

#### 1. Provisionar Backend Remoto

```bash
cd infra/bootstrap
terraform init
terraform apply -var="s3_bucket=tu-nombre-bucket-unico"
```

#### 2. Configurar Backend en App

Edita `infra/app/providers.tf` y agrega el bloque backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "tu-nombre-bucket-unico"
    key            = "cheese-factory/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-tcf-lock"
    encrypt        = true
  }
}
```

#### 3. Desplegar Infraestructura de Aplicación

```bash
cd infra/app
terraform init -reconfigure
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## 📊 Visualización del Flujo de Servicios

**¿Quieres ver cómo fluyen los servicios cuando aplicas la infraestructura?**

Consulta la siguiente documentación con diagramas interactivos:

- **🎯 [Diagramas Rápidos](QUICK_DIAGRAMS.md)** - Visualización del flujo principal y arquitectura en AWS
- **🏗️ [Arquitectura Detallada](ARCHITECTURE.md)** - Diagramas completos de infraestructura, seguridad y monitoreo
- **🔄 [Flujo de Despliegue](DEPLOYMENT_FLOW.md)** - Timeline paso a paso de `terraform apply`

## 📁 Estructura del Proyecto

```
AUY1103-IaC/
├── docs/
│   └── README.md                 # Documentación principal
├── infra/
│   ├── bootstrap/                # Backend remoto y estado
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars.example
│   └── app/                      # Infraestructura de aplicación
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf
│       ├── user_data.sh.tpl
│       └── terraform.tfvars.example
```

## 🔐 Buenas Prácticas de Seguridad

- ✅ Mantener credenciales fuera del repositorio (usar AWS profiles o variables de entorno)
- ✅ Utilizar nombres único para el bucket S3 (deben ser globalmente únicos)
- ✅ Siempre ejecutar `terraform plan` antes de `terraform apply`
- ✅ Usar `terraform init -reconfigure` cuando cambies la configuración del backend
- ✅ Habilitar versionado en el bucket S3 para recuperación de estados anteriores
- ✅ Implementar políticas de cifrado en el bucket S3 y tabla DynamoDB
- ✅ Utilizar state locking para evitar cambios concurrentes

## 📚 Documentación Adicional

### 📊 Visualización y Diagramas
- [🏗️ Arquitectura - Diagramas y Flujos](ARCHITECTURE.md) - Visualización completa de la infraestructura
- [🔄 Flujo de Despliegue](DEPLOYMENT_FLOW.md) - Timeline y fases de `terraform apply`

### 🔧 Módulos
- [🔧 Bootstrap](../infra/bootstrap/README.md) - Configuración del estado remoto
- [🚀 App](../infra/app/README.md) - Infraestructura de aplicación

## ⚙️ Variables Principales

| Componente | Variable | Descripción |
|-----------|----------|-------------|
| Bootstrap | `s3_bucket` | Nombre único del bucket S3 |
| Bootstrap | `aws_region` | Región AWS (default: us-east-1) |
| App | `environment` | Entorno de despliegue (dev/prod) |
| App | `my_public_ip` | IP para acceso SSH administrativo |
| App | `docker_images` | Lista de imágenes Docker a desplegar |

## 🛠️ Mantenimiento

### Verificar Estado

```bash
terraform state list
terraform state show [resource]
```

### Destruir Infraestructura

```bash
cd infra/app
terraform destroy -var-file="terraform.tfvars"

cd infra/bootstrap
terraform destroy -var="s3_bucket=tu-nombre-bucket-unico"
```

---

*Última actualización: Mayo 2026*
