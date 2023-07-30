variable "external_dns_chart_name" {
  type    = string
  default = ""
}

variable "external_dns_chart_repo" {
  type    = string
  default = ""
}

variable "external_dns_chart_version" {
  type    = string
  default = ""
}

variable "external_dns_values" {
  type    = map(any)
  default = {}
}

variable "dns_hosted_zone" {
  type    = string
  default = "psinc.click"
}

variable "external_dns_iam_role" {
  type    = string
  default = ""
}

variable "cluster_endpoint" {
  type    = string
  default = ""
}

variable "admin_users" {
  default = ["aamer"]
}

variable "developer_users" {
  default = ["anand", "mani"]
}

variable "mapUsers" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type    = string
  default = ""
}
