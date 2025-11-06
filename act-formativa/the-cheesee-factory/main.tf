data "aws_availability_zones" "available" {
  state = "available"

}
#crear VPC con subnets públicas y privadas
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Terraform   = "true"
    Environment = var.enviroment
  }
}
#crear grupo de seguridad para permitir tráfico ALB
module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"
  name        = "alb-sg"
  description = "Security group for alb with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}
#crear grupo de seguridad para permitir tráfico EC2 (HTTP publico y SSH a my ip publica)
module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2-sg"
  description = "SG que permite HTTP a todos y SSH solo a mi IP"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]   # CIDR para reglas predefinidas
  ingress_rules       = ["http-80-tcp"] # Regla predefinida para HTTP puerto 80

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH acceso solo a mi IP"
      cidr_blocks = var.my_public_ip
    }
  ]
  egress_rules = ["all-all"]
}
#crear instancias EC2 en subredes privadas

locals {
  instance_type = var.enviroment == "prod" ? "t3.small" : "t3.micro"
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
    Name = "${var.enviroment}-ec2-${count.index + 1}"
  }
}


# ALB en subredes públicas y asociado correctamente al SG
resource "aws_lb" "this" {
  name               = "cheesee-${var.enviroment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id] # Asociación del SG creado
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "cheesee-${var.enviroment}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "cheesee-${var.enviroment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
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
