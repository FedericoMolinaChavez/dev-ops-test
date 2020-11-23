resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.http_method
  authorization = var.authorization
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.main.resource_id
  http_method = aws_api_gateway_method.main.http_method


  integration_http_method = var.integration_http_method
  type                    = var.integration_type
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "apigw" {
  depends_on  = [aws_api_gateway_integration.main]
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = var.stage
}


resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"


  source_arn = "${aws_api_gateway_deployment.apigw.execution_arn}/*/*"
}






