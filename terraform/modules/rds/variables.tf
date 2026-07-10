variable "identifier" {
  description = "The RDS instance identifier"
  type        = string
}

variable "engine" {
  description = "The database engine to use
  type        = "the database engine to use"
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
  description = "Specifies if the RDS:00"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}