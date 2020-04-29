output endpoint {
  # value = join("/", [ aws_api_gateway_deployment.this.invoke_url , aws_api_gateway_stage.this.stage_name])
  value = "https://${aws_api_gateway_domain_name.this.domain_name}/"
}
