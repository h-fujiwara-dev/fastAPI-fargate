output "tfstate_bucket" {
  description = "S3 bucket name for Terraform remote state. Copy into envs/*/backend.hcl."
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_lock_table" {
  description = "DynamoDB table name for Terraform state locking. Copy into envs/*/backend.hcl."
  value       = aws_dynamodb_table.tfstate_lock.name
}
