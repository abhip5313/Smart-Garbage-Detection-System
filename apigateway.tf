resource "aws_apigatewayv2_api" "api" {

  name          = "image-recognition-api"
  protocol_type = "HTTP"

  cors_configuration {

    allow_origins = ["*"]

    allow_methods = [
      "GET",
      "POST",
      "OPTIONS"
    ]

    allow_headers = [
      "content-type"
    ]

  }

}
resource "aws_apigatewayv2_integration" "upload_integration" {

  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /upload-url" # ✅ correct
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

resource "aws_apigatewayv2_integration" "result_integration" {

  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.result_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "result_route" {

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /result"
  target    = "integrations/${aws_apigatewayv2_integration.result_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {

  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "all_results_integration" {

  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.all_results_lambda.invoke_arn

}

resource "aws_apigatewayv2_route" "all_results_route" {

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /all-results"
  target    = "integrations/${aws_apigatewayv2_integration.all_results_integration.id}"

}

resource "aws_lambda_permission" "allow_apigw_all_results" {

  statement_id  = "AllowAPIGatewayInvokeAllResults"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.all_results_lambda.function_name
  principal     = "apigateway.amazonaws.com"

}