resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/ec2/nginx/access"
  retention_in_days = 14
}
