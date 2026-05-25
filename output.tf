output "website_url" {

  value = aws_s3_bucket_website_configuration.ui_configuration.website_endpoint


}

output "api_gateway_url" {

  value = aws_apigatewayv2_api.api.api_endpoint

}

output "cdn_url" {
  value = aws_cloudfront_distribution.ui_cdn.domain_name
}