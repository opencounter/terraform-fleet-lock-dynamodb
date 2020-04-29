resource aws_api_gateway_rest_api this {
  name = module.label.id
  tags = module.label.tags

  policy = data.aws_iam_policy_document.api_policy.json

  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

data aws_iam_policy_document api_policy {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["execute-api:Invoke"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    effect    = "Deny"
    resources = ["*"]
    actions   = ["execute-api:Invoke"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource aws_api_gateway_resource v1 {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "v1"
}

resource aws_api_gateway_resource this {
  for_each = toset([
    "pre-reboot",
    "steady-state",
  ])

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = each.key
}

resource aws_api_gateway_method POST {
  for_each = aws_api_gateway_resource.this

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value.id
  http_method   = "POST"
  authorization = "NONE"

  request_validator_id = aws_api_gateway_request_validator.both.id
  request_models = {
    "application/json" = aws_api_gateway_model.this.name
  }
  request_parameters = {
    "method.request.header.fleet-lock-protocol" = true
  }
}

resource aws_api_gateway_method_settings this {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = var.debug_logging
  }
}

resource aws_api_gateway_request_validator both {
  name                        = module.label.id
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  validate_request_parameters = true
  validate_request_body       = true
}

resource aws_api_gateway_method_response response_200 {
  for_each = aws_api_gateway_resource.this

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.POST[each.key].http_method

  status_code = "200"
}

resource aws_api_gateway_integration_response response_200 {
  for_each = aws_api_gateway_method_response.response_200

  rest_api_id       = each.value.rest_api_id
  resource_id       = each.value.resource_id
  http_method       = each.value.http_method
  status_code       = each.value.status_code
  selection_pattern = "200"
}

resource aws_api_gateway_method_response response_400 {
  for_each = aws_api_gateway_resource.this

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.POST[each.key].http_method

  status_code = "400"
}

resource aws_api_gateway_integration_response response_400 {
  for_each = aws_api_gateway_resource.this

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.POST[each.key].http_method
  status_code = aws_api_gateway_method_response.response_400[each.key].status_code
}

resource aws_api_gateway_stage this {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage
  tags          = module.label.tags

  cache_cluster_size   = "0.5"
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format          = jsonencode(local.access_log_format)
  }
}

locals {
  access_log_format = {
    caller             = "$context.identity.caller"
    httpMethod         = "$context.httpMethod"
    integrationLatency = "$context.integrationLatency"
    integrationStatus  = "$context.integrationStatus"
    ip                 = "$context.identity.sourceIp"
    protocol           = "$context.protocol"
    requestId          = "$context.requestId"
    requestTime        = "$context.requestTime"
    resourcePath       = "$context.resourcePath"
    responseLatency    = "$context.responseLatency"
    responseLength     = "$context.responseLength"
    stage              = "$context.stage"
    status             = "$context.status"
    user               = "$context.identity.user"
    wafResponseCode    = "$context.wafResponseCode"
    webaclArn          = "$context.webaclArn"
    xrayTraceId        = "$context.xrayTraceId"
  }
}

resource aws_api_gateway_deployment this {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [
    aws_api_gateway_integration.pre_reboot,
    aws_api_gateway_integration.steady_state,
    aws_api_gateway_integration_response.response_200,
    aws_api_gateway_integration_response.response_400,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_api_gateway_model this {
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = "FleetLock"
  description  = "JSON schema"
  content_type = "application/json"
  schema       = file("${path.module}/json_schema.json")
}

resource aws_cloudwatch_log_group access_logs {
  name = "/api-gateway/${aws_api_gateway_rest_api.this.name}/${var.stage}"
  tags = module.label.tags
}
