# Lambda Function for Cost Alerts
# Monitors AWS costs and sends alerts when thresholds are exceeded

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

variable "budget_amount" {
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

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda" {
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

# Attach AWS managed policies for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for CloudWatch Logs (additional permissions if needed)
data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_cloudwatch" {
  name   = "${var.function_name}-cloudwatch-policy"
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_cloudwatch.arn
}

# Policy for Cost Explorer
data "aws_iam_policy_document" "lambda_ce" {
  statement {
    effect = "Allow"

    actions = [
      "ce:GetCostAndUsage",
      "ce:GetDimensionValues",
      "ce:GetReservationCoverage",
      "ce:GetReservationUtilization"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "lambda_ce" {
  name   = "${var.function_name}-ce-policy"
  policy = data.aws_iam_policy_document.lambda_ce.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_ce_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_ce.arn
}

# Policy for SNS Publish
data "aws_iam_policy_document" "lambda_sns" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      var.sns_topic_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_sns" {
  name   = "${var.function_name}-sns-policy"
  policy = data.aws_iam_policy_document.lambda_sns.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_sns.arn
}

# Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN   = var.sns_topic_arn
      BUDGET_AMOUNT   = var.budget_amount
      BUDGET_PERIOD   = var.budget_period
      TIME_ZONE       = "UTC"
    }
  }

  tags = var.tags
}

# EventBridge Rule to trigger the Lambda on a schedule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  description         = "Schedule to trigger the cost monitoring Lambda"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.this.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
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