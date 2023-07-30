variable "dns_hosted_zone" {
  default = "psinc.click"
}

variable "load_balancer_name" {
  default = "aws-load-balancer-controller"
}

variable "alb_controller_iam_role" {
  default = "aws-load-balancer-controller"
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet cidr block"
}

variable "alb_controller_chart_name" {
  type        = string
  description = ""
}

variable "alb_controller_chart_repo" {
  type        = string
  description = ""
}

variable "alb_controller_chart_version" {
  type        = string
  description = ""
}

variable "name_prefix" {
  type    = string
  default = "development"
}
