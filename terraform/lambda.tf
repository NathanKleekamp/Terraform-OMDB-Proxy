locals {
  function_name = "OMDB_Proxy"
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_secretsmanager_secret" "omdb_api_key" {
  name = "OmdbApiKey"
}

data "aws_secretsmanager_secret_version" "omdb_api_key" {
  secret_id = "${data.aws_secretsmanager_secret.omdb_api_key.id}"
}

resource "aws_lambda_function" "omdb_proxy" {
  function_name = local.function_name

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "${var.s3_bucket}"
  s3_key    = "version/${var.app_version}/build.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs10.x"

  role = "${aws_iam_role.lambda_exec.arn}"

	environment {
    variables = {
      OMDB_KEY = jsondecode(data.aws_secretsmanager_secret_version.omdb_api_key.secret_string)["OmdbApiKey"]
    }
	}

  depends_on = [
    "aws_iam_role_policy_attachment.lambda_queue",
    "aws_iam_role_policy_attachment.lambda_logs",
    "aws_cloudwatch_log_group.omdb_proxy"
  ]
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_omdb_proxy_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name = "serverless_omdb_proxy_lambda_logging"
  path = "/"
  description = "IAM policy for logging from the OMDB proxy lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_queue" {
  name = "serverless_omdb_proxy_lambda_queue"
  path = "/"
  description = "IAM policy for interacting with SQS from the OMDB proxy lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.movie_queue.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda_queue" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_queue.arn}"
}

resource "aws_cloudwatch_log_group" "omdb_proxy" {
  name = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  parent_id   = "${aws_api_gateway_rest_api.omdb_proxy.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.omdb_proxy.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  resource_id   = "${aws_api_gateway_rest_api.omdb_proxy.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.omdb_proxy.invoke_arn}"
}

resource "aws_api_gateway_deployment" "omdb_proxy" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.omdb_proxy.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.omdb_proxy.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.omdb_proxy.execution_arn}/*/*"
}
