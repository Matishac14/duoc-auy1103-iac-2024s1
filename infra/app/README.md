# 🚀 App Infrastructure

Módulo de infraestructura que despliega la plataforma de servicios de "The Cheese Factory" en AWS.

## 🏗️ Arquitectura Completa tras Apply

```mermaid
graph TB
    Internet["🌐 INTERNET<br/>Usuarios"]
    
    Internet -->|"HTTP:80"| ALB["⚖️ Application Load Balancer<br/>cheesee-env-alb-xxx.elb.amazonaws.com<br/>Port: 80/443"]
    
    ALB -->|"SG: ALB-SG<br/>Ingress: 0.0.0.0/0:80/443<br/>Egress: All"| ALB_SG["✅ ALB Security Group"]
    
    ALB -->|"Health Check: /<br/>Round-robin<br/>Matcher: 200-399"| TG["Target Group<br/>cheesee-env-tg"]
    
    subgraph VPC["VPC: 10.0.0.0/16"]
        subgraph Public["PUBLIC SUBNETS<br/>3 AZ"]
            ALB_NET["ALB Placement"]
            NAT["🔄 NAT Gateway<br/>EIP: Elástica"]
        end
        
        subgraph Private["PRIVATE SUBNETS (AZ 1, 2, 3)<br/>Security: Zero Trust"]
            subgraph AZ1["AZ-1: 10.0.11.0/24"]
                EC2_1["🖥️ EC2-1<br/>t3.micro/small<br/>10.0.11.X"]
                SG1["SG: EC2-SG<br/>Ingress: ALB:80<br/>Ingress: MY_IP:22"]
                Docker1["🐳 Docker<br/>Cheddar<br/>Port: 8080"]
                App1["🍕 Aplicación"]
            end
            
            subgraph AZ2["AZ-2: 10.0.12.0/24"]
                EC2_2["🖥️ EC2-2<br/>t3.micro/small<br/>10.0.12.X"]
                SG2["SG: EC2-SG<br/>Ingress: ALB:80<br/>Ingress: MY_IP:22"]
                Docker2["🐳 Docker<br/>Brie<br/>Port: 8080"]
                App2["🍕 Aplicación"]
            end
            
            subgraph AZ3["AZ-3: 10.0.13.0/24"]
                EC2_3["🖥️ EC2-3<br/>t3.micro/small<br/>10.0.13.X"]
                SG3["SG: EC2-SG<br/>Ingress: ALB:80<br/>Ingress: MY_IP:22"]
                Docker3["🐳 Docker<br/>Mozzarella<br/>Port: 8080"]
                App3["🍕 Aplicación"]
            end
        end
    end
    
    TG --> EC2_1
    TG --> EC2_2
    TG --> EC2_3
    
    EC2_1 --> SG1
    SG1 --> Docker1
    Docker1 --> App1
    
    EC2_2 --> SG2
    SG2 --> Docker2
    Docker2 --> App2
    
    EC2_3 --> SG3
    SG3 --> Docker3
    Docker3 --> App3
    
    EC2_1 --> NAT
    EC2_2 --> NAT
    EC2_3 --> NAT
    NAT -->|"Salida a Internet"| Internet
    
    style Internet fill:#FF6B6B
    style ALB fill:#FFC107
    style VPC fill:#E3F2FD
    style Public fill:#C8E6C9
    style Private fill:#BBDEFB
    style NAT fill:#4CAF50
```

## 🔄 Flujo de Tráfico HTTP

```mermaid
sequenceDiagram
    participant User as 👤 Usuario
    participant DNS as 🌐 DNS
    participant ALB as ⚖️ ALB
    participant EC2 as 🖥️ EC2
    participant Docker as 🐳 Docker
    participant App as 🍕 App
    
    User->>DNS: 1. curl cheesee-alb-xxx.elb.amazonaws.com
    DNS-->>User: 2. IP del ALB
    User->>ALB: 3. GET / HTTP/1.1
    ALB->>ALB: 4. Health Check ✅
    ALB->>EC2: 5. Round-robin EC2:8080
    EC2->>Docker: 6. Forwarding port
    Docker->>App: 7. Request app
    App-->>Docker: 8. Response
    Docker-->>EC2: 9. Response :8080
    EC2-->>ALB: 10. Response :80
    ALB-->>User: 11. HTTP 200 OK
    
    Note over User,App: Próximo request: Round-robin a otro EC2
```

## ⏺️ Ciclo de Vida de Recursos

```mermaid
flowchart TD
    Start["🚀 terraform apply<br/>infra/app"]
    
    Fase1["FASE 1: Networking<br/>2-3 minutos"]
    Step1_1["✅ VPC 10.0.0.0/16<br/>Creating → Available"]
    Step1_2["✅ Subnetes (6)<br/>Públicas + Privadas"]
    Step1_3["✅ Gateways<br/>IGW + NAT"]
    
    Fase2["FASE 2: Seguridad<br/>1 minuto"]
    Step2_1["✅ ALB-SG<br/>Ingress: 0.0.0.0/0:80/443"]
    Step2_2["✅ EC2-SG<br/>Zero Trust Model"]
    
    Fase3["FASE 3: Balanceo<br/>2-3 minutos"]
    Step3_1["✅ ALB Creada<br/>Provisioning → Active"]
    Step3_2["✅ Target Group<br/>cheesee-env-tg"]
    Step3_3["✅ Listener<br/>ALB:80 → TG"]
    
    Fase4["FASE 4: Cómputo + Docker<br/>4-5 minutos"]
    Step4_1["✅ EC2-1 Lanzada<br/>User Data: Docker pull + run"]
    Step4_2["✅ EC2-2 Lanzada<br/>User Data: Docker pull + run"]
    Step4_3["✅ EC2-3 Lanzada<br/>User Data: Docker pull + run"]
    Step4_4["✅ Targets Registrados<br/>Status: initial → healthy"]
    
    End["✅ INFRAESTRUCTURA OPERATIVA<br/>DNS Accesible<br/>Tráfico Distribuido<br/>Health Checks: PASSING"]
    
    Start --> Fase1
    Fase1 --> Step1_1 --> Step1_2 --> Step1_3
    
    Step1_3 --> Fase2
    Fase2 --> Step2_1 --> Step2_2
    
    Step2_2 --> Fase3
    Fase3 --> Step3_1 --> Step3_2 --> Step3_3
    
    Step3_3 --> Fase4
    Fase4 --> Step4_1 --> Step4_2 --> Step4_3 --> Step4_4
    
    Step4_4 --> End
    
    style Start fill:#90EE90
    style Fase1 fill:#BBDEFB
    style Fase2 fill:#FFE0B2
    style Fase3 fill:#FFC107
    style Fase4 fill:#FF9800
    style End fill:#4CAF50
```

## 📊 Descripción

Este módulo provisiona una infraestructura de aplicación escalable y segura en AWS, incluyendo componentes de red, balanceo de carga y cómputo con integración de contenedores Docker.

## 🏗️ Arquitectura

### Componentes Principales

#### Red (VPC)
- **VPC**: Red privada virtual con segmentación de subredes
- **Subredes Públicas**: Alojan el Application Load Balancer
- **Subredes Privadas**: Alojan instancias EC2 para mayor seguridad

#### Balanceo de Carga
- **Application Load Balancer (ALB)**: Distribuye tráfico HTTP/HTTPS
- **Target Groups**: Configuración de objetivos para equilibrio de carga

#### Seguridad
- **Security Groups**: Implementación de modelo Zero Trust
  - ALB: Acepta tráfico de internet en puertos 80/443
  - EC2: Solo acepta tráfico proveniente del ALB
  - SSH: Restringido a IP administrativa específica

#### Cómputo y Contenedores
- **Instancias EC2**: Servidores con integración Docker
- **User Data Script**: Despliegue automático de contenedores al iniciar instancias
- **Docker Images**: Sabores de queso (imágenes) personalizadas

## 📝 Variables de Configuración

| Variable | Tipo | Descripción | Obligatorio |
|----------|------|-------------|------------|
| `environment` | string | Entorno de despliegue (dev/prod) | Sí |
| `my_public_ip` | string | IP permitida para acceso SSH | Sí |
| `docker_images` | list(string) | Lista de imágenes Docker a desplegar | Sí |
| `aws_region` | string | Región AWS | No |

### Notas sobre Variables

- **environment**: Define el tamaño de instancia EC2 (dev: t2.micro, prod: t2.small)
- **my_public_ip**: Use CIDR notation (ej: 203.0.113.42/32)
- **docker_images**: Sabores de queso disponibles (ej: ["cheddar", "brie", "mozzarella"])

## 🚀 Guía de Despliegue

### Requisitos Previos

- Backend remoto ya configurado (ver [Bootstrap](../bootstrap/README.md))
- Archivo `terraform.tfvars` con valores requeridos
- AWS CLI configurado
- Terraform >= 1.0

### Pasos de Despliegue

#### 1. Preparar Variables

Copia el archivo de ejemplo y actualiza con tus valores:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars con tus valores
```

#### 2. Inicializar Terraform

```bash
terraform init
```

#### 3. Revisar Plan

```bash
terraform plan -var-file="terraform.tfvars"
```

#### 4. Aplicar Configuración

```bash
terraform apply -var-file="terraform.tfvars"
```

#### 5. Obtener Outputs

```bash
terraform output
```

Salida esperada:
```
alb_dns_name = "cheesee-dev-alb-12345.elb.amazonaws.com"
alb_arn = "arn:aws:elasticloadbalancing:..."
ec2_instance_ids = ["i-001", "i-002", "i-003"]
ec2_private_ips = ["10.0.11.10", "10.0.12.10", "10.0.13.10"]
vpc_id = "vpc-12345"
private_subnet_ids = ["subnet-001", "subnet-002", "subnet-003"]
public_subnet_ids = ["subnet-101", "subnet-102", "subnet-103"]
```

### Diagrama: Relación Outputs-Recurso

```mermaid
graph TB
    Outputs["📤 TERRAFORM OUTPUTS"]
    
    Outputs --> ALB_Out["⚖️ ALB Outputs"]
    Outputs --> EC2_Out["🖥️ EC2 Outputs"]
    Outputs --> VPC_Out["🌐 VPC Outputs"]
    Outputs --> TG_Out["🎯 Target Group Outputs"]
    
    ALB_Out --> DNS["alb_dns_name<br/>cheesee-env-alb-xxx.elb.amazonaws.com<br/>Usar: Acceso web"]
    ALB_Out --> ALB_ARN["alb_arn<br/>arn:aws:elasticloadbalancing:...<br/>Usar: Referencia en otras stacks"]
    
    EC2_Out --> IDS["ec2_instance_ids<br/>[i-001, i-002, i-003]<br/>Usar: SSH, monitoreo"]
    EC2_Out --> IPS["ec2_private_ips<br/>[10.0.11.10, ...]<br/>Usar: Acceso interno"]
    
    VPC_Out --> VPC_ID["vpc_id<br/>vpc-12345<br/>Usar: Referencia red"]
    VPC_Out --> PRIV_SN["private_subnet_ids<br/>[subnet-001, ...]<br/>Usar: Nuevos recuros privados"]
    VPC_Out --> PUB_SN["public_subnet_ids<br/>[subnet-101, ...]<br/>Usar: Nuevos resursos públicos"]
    
    TG_Out --> TG_ARN["target_group_arn<br/>arn:aws:elasticloadbalancing:...<br/>Usar: Modificar targets"]
    
    style Outputs fill:#E3F2FD
    style ALB_Out fill:#FFC107
    style EC2_Out fill:#4CAF50
    style VPC_Out fill:#2196F3
    style TG_Out fill:#FF9800
    style DNS fill:#FFFDE7
    style IDS fill:#C8E6C9
    style PRIV_SN fill:#BBDEFB
```

## 📊 Monitoreo y Verificación

### Verificar Estado de la Aplicación

1. **Acceder a la Consola de AWS**
   - Ve a EC2 → Load Balancers
   - Busca el ALB "cheese-factory-alb"

2. **Verificar Targets Healthy**
   - EC2 → Target Groups → cheese-factory-tg
   - Confirma que el estado de los targets es "Healthy"

3. **Acceder a la Aplicación**
   - DNS del ALB estará disponible en outputs
   - Ejemplo: `http://cheese-factory-alb-xxx.us-east-1.elb.amazonaws.com`

### Diagrama: Estados de Salud

```mermaid
graph TB
    subgraph HealthCheck["TARGET GROUP HEALTH CHECKS"]
        T1["🎯 Target 1<br/>EC2-1: 10.0.11.X"]
        T2["🎯 Target 2<br/>EC2-2: 10.0.12.X"]
        T3["🎯 Target 3<br/>EC2-3: 10.0.13.X"]
    end
    
    T1 --> T1_Check["✅ Status: Healthy<br/>Path: /<br/>Response: 200-399<br/>Intervalo: 30s"]
    T2 --> T2_Check["✅ Status: Healthy<br/>Path: /<br/>Response: 200-399<br/>Intervalo: 30s"]
    T3 --> T3_Check["✅ Status: Healthy<br/>Path: /<br/>Response: 200-399<br/>Intervalo: 30s"]
    
    T1_Check --> ALB_Good["⚖️ ALB Decision<br/>✅ Enviar tráfico"]
    T2_Check --> ALB_Good
    T3_Check --> ALB_Good
    
    T1_Unhealthy["❌ Target UNHEALTHY<br/>Port 8080 no escucha"]
    T1_Unhealthy --> Reason1["Razones posibles:<br/>• Docker no corriendo<br/>• App error<br/>• SG bloqueando"]
    
    Reason1 --> ALB_Block["⚖️ ALB Decision<br/>❌ NO enviar tráfico<br/>Marca como Unhealthy<br/>Intenta recuperar c/30s"]
    
    style HealthCheck fill:#E3F2FD
    style ALB_Good fill:#C8E6C9
    style ALB_Block fill:#FFCDD2
```

### Logs y Debugging

```bash
# Ver logs de user_data
ssh -i tu_clave ec2-user@<instance-ip>
less /var/log/cloud-init-output.log

# Ver estado de Docker
docker ps -a
docker logs <container-id>
```

## 🔄 Operaciones Comunes

### Escalar Instancias

Edita `terraform.tfvars` y modifica `instance_count`:

```hcl
instance_count = 3
terraform apply -var-file="terraform.tfvars"
```

### Cambiar Imágenes Docker

```bash
terraform apply -var="docker_images=[\"brie\",\"swiss\"]"
```

### Actualizar Security Group

```hcl
# En terraform.tfvars
my_public_ip = "nueva.ip.publica/32"
terraform apply -var-file="terraform.tfvars"
```

## 🗑️ Destruir Infraestructura

```bash
terraform destroy -var-file="terraform.tfvars"
```

## 📚 Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| `main.tf` | Configuración principal de recursos |
| `variables.tf` | Definición de variables de entrada |
| `outputs.tf` | Outputs exportados (ALB DNS, IPs, etc.) |
| `providers.tf` | Configuración de providers y backend |
| `user_data.sh.tpl` | Script de inicialización de instancias |
| `backend.tf` | Configuración del estado remoto |

## ⚠️ Consideraciones Importantes

- El ALB tarda ~2 minutos en alcanzar estado "InService"
- Asegúrate de usar una IP correcta en `my_public_ip` para acceso SSH
- Los costos dependen del entorno seleccionado y cantidad de instancias
- El cifrado de EBS está habilitado por defecto en todas las instancias

## 🔐 Seguridad

- ✅ Security Groups con principio de menor privilegio
- ✅ Acceso SSH restringido a IP específica
- ✅ VPC privada para instancias EC2
- ✅ ALB con permisos restringidos de internet
- ✅ Cifrado de datos en tránsito y en reposo

### Diagrama: Capas de Seguridad (Zero Trust)

```mermaid
graph TB
    Internet["🌐 INTERNET<br/>Acceso sin restricciones"]
    
    Internet -->|"Permite\nHTTP/HTTPS"| Layer2["🛡️ CAPA 2: ALB Security Group<br/>Ingress: 0.0.0.0/0:80/443<br/>Egress: All traffic"]
    
    Internet -->|"Deniega\ntodo lo demás"| Blocked["❌ RECHAZADO"]
    
    Layer2 -->|"Permite\nPort 80"| Layer3["🔐 CAPA 3: EC2 Security Group<br/>Zero Trust Model"]
    
    Layer3 --> Rule1["✅ Ingress: ALB-SG:80<br/>Tráfico de aplicación"]
    Layer3 --> Rule2["✅ Ingress: MY_IP:22<br/>SSH administrativo"]
    Layer3 --> Rule3["✅ Egress: All traffic<br/>Salida a Internet"]
    
    Rule1 --> Layer4["🔒 CAPA 4: Network<br/>Subnetes Privadas"]
    Rule2 --> Layer4
    Rule3 --> Layer4
    
    Layer4 --> Private["❌ Sin IP pública<br/>✅ NAT Gateway para salida<br/>✅ Solo tráfico autorizado"]
    
    Private --> Result["✅ ARQUITECTURA SEGURA<br/>Principio: Menor Privilegio<br/>Modelo: Zero Trust"]
    
    style Internet fill:#FF6B6B
    style Layer2 fill:#FFC107
    style Layer3 fill:#FF5722
    style Layer4 fill:#4CAF50
    style Result fill:#90EE90
    style Blocked fill:#FFCDD2
```

---

## 📚 Archivos Principales
