# Provides a resource to manage AWS Secrets Manager secret metadata.
resource "aws_secretsmanager_secret" "api_key" {
  name        = "konnichiwa/api-key"
  description = "API Key for Konnichiwa service"

  tags = {
    # Environment = var.environment
    Service     = "konnichiwa"
  }
}

# Output the ARN for use in ECS task definition
output "api_key_secret_arn" {
  value = aws_secretsmanager_secret.api_key.arn
}
