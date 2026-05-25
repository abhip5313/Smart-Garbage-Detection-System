resource "aws_dynamodb_table" "result_table" {
  name         = "ImageRecognitionResults"
  billing_mode = "PAY_PER_REQUEST"

  # 🔥 ONLY PRIMARY KEY (range_key काढला)
  hash_key = "ImageID"

  attribute {
    name = "ImageID"
    type = "S"
  }

  # 🔥 OPTIONAL (future filtering)
  attribute {
    name = "severity"
    type = "S"
  }

  global_secondary_index {
    name            = "severity-index"
    hash_key        = "severity"
    projection_type = "ALL"
  }

  # 🔥 TTL ENABLE (auto delete after 7 days)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Project = "GarbageDetection"
  }
}