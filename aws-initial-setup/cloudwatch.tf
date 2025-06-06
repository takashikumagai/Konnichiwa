resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${var.project_name}"

  tags = {
    Name = "${var.project_name}-log-group"
  }
}
