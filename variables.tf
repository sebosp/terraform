variable "env" {
  default = "prod"
}
locals {
  common_tags = "${map(
    "Project", "sys",
    "env",     "${var.env}",
  )}"
}
