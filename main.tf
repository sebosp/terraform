provider "aws" {
}
provider "google" {
  project = "${var.google_project}"
}
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tf-state.sebosp.com"
    key            = "tf-state"
    dynamodb_table = "tf-state-sebosp"
  }
}
