# ================= UPLOAD LAMBDA =================

data "archive_file" "upload_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/upload_lambda.py"
  output_path = "${path.module}/lambda/upload_lambda.zip"
}

# ================= RESULT LAMBDA =================

data "archive_file" "result_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/get_result_lambda.py"
  output_path = "${path.module}/lambda/get_result_lambda.zip"
}

resource "aws_lambda_function" "result_lambda" {
  function_name = "GetImageResultLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_result_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = data.archive_file.result_zip.output_path
  source_code_hash = data.archive_file.result_zip.output_base64sha256
}


# ================= UPLOAD LAMBDA =================

resource "aws_lambda_function" "upload_lambda" {
  function_name = "UploadImageLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "upload_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }
}

# ================= PROCESS LAMBDA =================

data "archive_file" "process_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/process_image_lambda.py"
  output_path = "${path.module}/lambda/process_image_lambda.zip"
}

resource "aws_lambda_function" "process_lambda" {
  function_name = "ProcessImageLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "process_image_lambda.lambda_handler"
  runtime       = "python3.10"

  timeout     = 60
  memory_size = 1024

  ephemeral_storage {
    size = 1024
  }

  architectures = ["x86_64"]

  filename         = data.archive_file.process_zip.output_path
  source_code_hash = data.archive_file.process_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }
}

# ================= API PERMISSIONS =================

resource "aws_lambda_permission" "allow_api_upload" {
  statement_id  = "AllowExecutionFromAPIGatewayUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_result" {
  statement_id  = "AllowExecutionFromAPIGatewayResult"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.result_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ================= ALL RESULTS LAMBDA ZIP =================

data "archive_file" "all_results_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/get_all_results_lambda.py"
  output_path = "${path.module}/lambda/get_all_results_lambda.zip"
}

# ================= ALL RESULTS LAMBDA =================

resource "aws_lambda_function" "all_results_lambda" {
  function_name = "GetAllResultsLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_all_results_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = data.archive_file.all_results_zip.output_path
  source_code_hash = data.archive_file.all_results_zip.output_base64sha256
}

resource "aws_lambda_permission" "allow_api_all_results" {
  statement_id  = "AllowExecutionFromAPIGatewayAllResults"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.all_results_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}



