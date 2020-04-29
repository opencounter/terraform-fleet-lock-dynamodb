data aws_iam_policy_document assume_by_api_gateway {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource aws_iam_role this {
  name               = module.label.id
  assume_role_policy = data.aws_iam_policy_document.assume_by_api_gateway.json
}

data aws_iam_policy_document role {
  statement {
    resources = [
      join(":", [aws_cloudwatch_log_group.access_logs.arn, "*", "*"]),
    ]
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
  }

  statement {
    resources = [aws_dynamodb_table.this.arn]
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]
  }
}

resource aws_iam_policy this {
  name   = module.label.id
  path   = "/"
  policy = data.aws_iam_policy_document.role.json
}


resource aws_iam_role_policy_attachment this {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
