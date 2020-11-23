
resource "aws_api_gateway_rest_api" "apigw" {
  name                     = var.apigw_name
  description              = var.description
  minimum_compression_size = var.minimum_compression_size
}

resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = var.path_part
}