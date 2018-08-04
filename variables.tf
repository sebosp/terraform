variable "env" {
  default = "prod"
}
variable "google_project" {
  default = "sebosp-main-666"
}
locals {
  common_tags = "${map(
    "Project", "sys",
    "env",     "${var.env}",
  )}"
}
