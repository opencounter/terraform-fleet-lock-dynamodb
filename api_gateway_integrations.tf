resource aws_api_gateway_integration pre_reboot {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this["pre-reboot"].id
  http_method = "POST"

  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.this.name}:dynamodb:action/UpdateItem"
  integration_http_method = "POST"
  credentials             = aws_iam_role.this.arn
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = jsonencode({
      TableName = aws_dynamodb_table.this.name

      ExpressionAttributeNames = {
        "#group" = "group"
        "#owner" = "owner"
      }

      ExpressionAttributeValues = {
        ":owner" = {
          S = "$input.path('$.client_params.id')"
        }
        ":now" = {
          N = "$context.requestTimeEpoch"
        }
        ":ttl" = {
          N = tostring(var.lease_duration * 1000)
        }
      }

      Key = {
        group = {
          S = "$input.path('$.client_params.group')"
        }
      }
      ConditionExpression = "attribute_not_exists(#group) OR #owner = :owner OR expires < :now"
      UpdateExpression    = "SET #owner = :owner, expires = :now + :ttl"
    })
  }
}

resource aws_api_gateway_integration steady_state {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this["steady-state"].id
  http_method = "POST"

  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.this.name}:dynamodb:action/DeleteItem"
  integration_http_method = "POST"
  credentials             = aws_iam_role.this.arn
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = jsonencode({
      TableName = aws_dynamodb_table.this.name

      ExpressionAttributeNames = {
        "#group" = "group"
        "#owner" = "owner"
      }

      ExpressionAttributeValues = {
        ":owner" = {
          S = "$input.path('$.client_params.id')"
        }
        ":now" = {
          N = "$context.requestTimeEpoch"
        }
      }

      Key = {
        group = {
          S = "$input.path('$.client_params.group')"
        }
      }
      ConditionExpression = "attribute_not_exists(#group) OR #owner = :owner OR expires < :now"
    })
  }
}
