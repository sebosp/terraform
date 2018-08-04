resource "aws_s3_bucket" "remote-state" {
    bucket = "tf-state.sebosp.com"
    acl    = "private"
    versioning {
      enabled = true
    }
    lifecycle {
      prevent_destroy = true
    }
    tags = "${merge(
      local.common_tags,
      map(
        "Name", "S3 Remote Terraform State Store"
      )
    )}"
}
resource "aws_dynamodb_table" "remote-state" {
  name           = "tf-state-sebosp"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "DynamoDB Terraform State Lock Table"
    )
  )}"
}
