data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Redes: VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# 2. Seguridad: SG para el ALB (Entrada Pública)
module "alb_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/http-80"
  name        = "${var.environment}-alb-sg"
  description = "Permite tráfico HTTP desde internet"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# 3. Seguridad: SG para EC2 (Zero Trust - Solo desde ALB)
module "ec2_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "${var.environment}-ec2-sg"
  description = "Permite tráfico HTTP solo desde el ALB y SSH desde mi IP"
  vpc_id      = module.vpc.vpc_id

  # Regla restrictiva: Solo el ALB puede hablar con las EC2 por el puerto 80
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "HTTP desde ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  # SSH restringido a tu IP
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH acceso administrativo"
      cidr_blocks = var.my_public_ip
    }
  ]

  egress_rules = ["all-all"]
}

# 4. Cómputo: EC2 en Subredes Privadas
locals {
  instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  count                       = length(var.docker_images)
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.instance_type
  subnet_id                   = module.vpc.private_subnets[count.index]
  associate_public_ip_address = false
  vpc_security_group_ids      = [module.ec2_sg.security_group_id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    image = var.docker_images[count.index]
  })

  tags = {
    Name = "${var.environment}-ec2-${count.index + 1}"
  }
}

# 5. Balanceo: ALB
resource "aws_lb" "this" {
  name               = "cheesee-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "cheesee-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "cheesee-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}