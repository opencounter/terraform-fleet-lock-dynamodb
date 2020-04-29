module label {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  stage      = var.stage
  name       = var.name
  attributes = []

  tags = {
    Environment = var.stage
    Purpose     = var.purpose
    managed_by  = "terraform"
  }
}

resource aws_resourcegroups_group this {
  name = module.label.id

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Environment"
          Values = [var.stage]
        },
        {
          Key    = "Purpose"
          Values = [var.purpose]
        }
      ]
    })
  }
}

data aws_caller_identity this {}
data aws_region this {}
