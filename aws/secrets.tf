# Provides a resource to manage AWS Secrets Manager secret metadata.
resource "aws_secretsmanager_secret" "api_key" {
  name        = "konnichiwa/konnichiwa-api-key"
  description = "API Key for Konnichiwa service"

  tags = {
    # Environment = var.environment
    Service     = "konnichiwa"
  }
}
