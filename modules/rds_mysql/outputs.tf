output "db_address" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "db_instance_id" {
  value = aws_db_instance.this.identifier
}

output "secret_arn" {
  description = "ARN of the RDS-managed master user secret in Secrets Manager."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
