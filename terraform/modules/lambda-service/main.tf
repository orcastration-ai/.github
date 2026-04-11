locals {
  function_name = "orca-${var.environment}-${var.service_name}"
  use_vpc       = length(var.subnet_ids) > 0
}

# --- Account Guard ---

data "aws_caller_identity" "current" {}

resource "terraform_data" "account_guard" {
  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = <<-EOT
        Active AWS account is ${data.aws_caller_identity.current.account_id}, but this var-file expects ${var.environment} in ${var.aws_account_id}.
        Fix GitHub Environment secrets: AWS_ROLE_ARN must be a role in the same account as Variable AWS_ACCOUNT_ID.
      EOT
    }
  }
}

# --- IAM ---

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  depends_on = [terraform_data.account_guard]

  name               = "${local.function_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  # CloudWatch Logs
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  # SSM Parameter Store read access
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/orca/${var.environment}/*"]
  }

  # Service-specific permissions
  dynamic "statement" {
    for_each = var.additional_iam_statements
    content {
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.service_name}-lambda-permissions"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = local.use_vpc ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "lambda" {
  depends_on = [terraform_data.account_guard]

  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.environment == "prod" ? 90 : 14
}

# --- Lambda Function ---

resource "aws_lambda_function" "this" {
  depends_on = [terraform_data.account_guard]

  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Placeholder — CI deploys code via `aws lambda update-function-code`
  filename = data.archive_file.placeholder.output_path

  environment {
    variables = merge({ ENVIRONMENT = var.environment }, var.environment_variables)
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda.name
    log_format = "JSON"
  }

  dynamic "vpc_config" {
    for_each = local.use_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  lifecycle {
    ignore_changes = [filename, last_modified, source_code_hash]
  }
}

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/.terraform/placeholder.zip"

  source {
    content  = "placeholder"
    filename = "bootstrap"
  }
}

# --- API Gateway Integration ---

data "aws_ssm_parameter" "api_gateway_id" {
  name = "/orca/${var.environment}/api-gateway/api-id"
}

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = data.aws_ssm_parameter.api_gateway_id.value
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  count     = length(var.routes)
  api_id    = data.aws_ssm_parameter.api_gateway_id.value
  route_key = "${var.routes[count.index].method} ${var.routes[count.index].path}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${data.aws_ssm_parameter.api_gateway_id.value}/*/*"
}

# --- SSM Parameters ---

resource "aws_ssm_parameter" "function_name" {
  depends_on = [terraform_data.account_guard]

  name        = "/orca/${var.environment}/${var.service_name}/lambda-function-name"
  description = "${var.service_name} Lambda function name"
  type        = "String"
  value       = aws_lambda_function.this.function_name
  overwrite   = true
}

resource "aws_ssm_parameter" "function_arn" {
  depends_on = [terraform_data.account_guard]

  name        = "/orca/${var.environment}/${var.service_name}/lambda-arn"
  description = "${var.service_name} Lambda function ARN"
  type        = "String"
  value       = aws_lambda_function.this.arn
  overwrite   = true
}
