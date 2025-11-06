variable "enviroment" {
  description = "The environment for the deployment (e.g., dev, prod)"
  type        = string
}
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "vpc_public_subnets" {
  description = "A list of public subnet CIDR blocks"
  type        = list(string)
}
variable "vpc_private_subnets" {
  description = "A list of private subnet CIDR blocks"
  type        = list(string)
}
variable "my_public_ip" {
  description = "Your public IP address in CIDR notation (e.g., x.x.x.x/32)"
  type        = string
}

variable "docker_images" {
  description = "Imágenes Docker a desplegar"
  type        = list(string)
  default     = ["errmcheesewensleydale", "errmcheesecheddar", "errmcheesestilton"]
}