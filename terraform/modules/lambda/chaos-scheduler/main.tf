# Chaos Scheduler Lambda Function
# Triggers Chaos Mesh experiments during off-hours for resilience testing

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "chaos-scheduler"
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Schedules Chaos Mesh experiments during off-hours for resilience testing"
}

variable "handler" {
  description = "The function entrypoint in your code"
  type        = string
  default     = "chaos_scheduler.lambda_handler"
}

variable "runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "The amount of time that Lambda allows a function to run before stopping it"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "The amount of memory available to the function"
  type        = number
  default     = 256
}

variable "schedule_expression" {
  description = "The schedule expression (e.g., 'rate(1 hour)', 'cron(0 2 * * ? *)')"
  type        = string
  default     = "cron(0 2 * * ? *)"  # 2 AM UTC daily
}

variable "chaos_experiments" {
  description = "List of chaos experiments to run"
  type        = list(string)
  default     = ["pod-kill", "network-latency", "cpu-stress"]
}

variable "namespaces" {
  description = "Namespaces to run chaos experiments in"
  type        = list(string)
  default     = ["default", "openwebui", "monitoring"]
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}

# IAM Role for Lambda
resource "aws_iam_role" "this" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policies for Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for Kubernetes access (to create ChaosMesh experiments)
resource "aws_iam_policy" "k8s_access" {
  name        = "${var.function_name}-k8s-access"
  description = "Permissions to create ChaosMesh experiments in EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kubernetes:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "k8s_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.k8s_access.arn
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.this.arn
  runtime       = var.runtime
  handler       = var.handler

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = var.timeout
  memory_size = var.memory_size

  environment {
    variables = {
      CHAOS_EXPERIMENTS = join(",", var.chaos_experiments)
      NAMESPACES        = join(",", var.namespaces)
      KUBECONFIG        = "/tmp/config"
      CLUSTER_NAME      = var.cluster_name
      REGION            = var.region
    }
  }

  tags = var.tags
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# EventBridge Rule to trigger the Lambda on schedule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  description         = "Schedule to trigger the chaos scheduler Lambda"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.this.arn
}

# Data sources
data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/lambda.zip"

  excludes = [
    "*.tf",
    "*.tfvars",
    ".terraform*",
    "README.md"
  ]
}

# Outputs
output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "The ARN to be used for invoking the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}