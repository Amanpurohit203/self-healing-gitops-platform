variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cost-alerts"
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Monitors AWS costs and sends SNS alerts when budget thresholds are exceeded"
}

variable "handler" {
  description = "The function entrypoint in your code"
  type        = string
  default     = "cost_monitor.lambda_handler"
}

variable "runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "The amount of time that Lambda allows a function to run before stopping it"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The amount of memory available to the function"
  type        = number
  default     = 256
}

variable "schedule_expression" {
  description = "The schedule expression (e.g., 'rate(1 hour)', 'cron(0 12 * * ? *)')"
  type        = string
  default     = "rate(1 hour)"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to publish alerts to"
  type        = string
}

variable "bud_amount" {
  description = "The budget amount in USD that triggers an alert"
  type        = number
  default     = 100.0
}

variable "budget_period" {
  description = "The period for the budget (MONTHLY, QUARTERLY, ANNUALLY)"
  type        = string
  default     = "MONTHLY"
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}