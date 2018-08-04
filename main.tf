provider "aws" {
}
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tf-state.sebosp.com"
    key            = "tf-state"
    dynamodb_table = "tf-state-sebosp"
  }
}
