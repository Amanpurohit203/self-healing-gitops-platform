# RDS Module for PostgreSQL (OpenWebUI Database)
# Creates a PostgreSQL RDS instance for OpenWebUI

variable "identifier" {
  description = "The RDS instance identifier"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The database engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "The instance type for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in GB"
  type        = number
  default     = 20
}

variable "name" {
  description = "The database name"
  type        = string
  default     = "postgres"
}

variable "username" {
  description = "The master username for the database"
  type        = string
}

variable "password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs to create the RDS instance in"
  type        = list(string)
}

variable "skip_final_snapshot" {
  description = "Whether to skip a final snapshot before deleting the instance"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of the final snapshot when deleting the instance"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether the database should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "The type of storage to use"
  type        = string
  default     = "gp2"
}

variable "port" {
  description = "The port on which the database accepts connections"
  type        = number
  default     = 5432
}

variable "parameter_group_name" {
  description = "The name of the parameter group to use"
  type        = string
  default     = "default.postgres15"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-subnet-group"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier              = var.identifier
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  name                    = var.name
  username                = var.username
  password                = var.password
  vpc_security_group_ids  = var.vpc_security_group_ids
  db_subnet_group_name    = aws_db_subnet_group.this.name
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  multi_az                = var.multi_az
  storage_type            = var.storage_type
  port                    = var.port
  parameter_group_name    = var.parameter_group_name

  # Performance Insights
  performance_interval = 60
  performance_indicators_enabled = true

  # Enable encryption
  storage_encrypted = true

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )
}

# Outputs
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