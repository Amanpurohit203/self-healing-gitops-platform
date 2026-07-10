output "address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.this.port
}

output "endpoint" {
  description = "The connection endpoint"
  value       = "${aws_db_instance.this.address}:${aws_db_instance.this.port}"
}

output "instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "username" {
  description = "The username for the database"
  value       = aws_db_instance.this.username
}

output "password" {
  description = "The password for the database"
  value       = aws_db_instance.this.password
  sensitive   = true
}