EC2 Observability with CloudWatch (Metrics + Logs) — Terraform Deployment

This Terraform module deploys an EC2 instance with full observability enabled using Amazon CloudWatch.
It configures:

✅ RAM Utilization metrics (using CloudWatch Agent — not available by default)
✅ NGINX access logs shipped to CloudWatch Logs
✅ IAM Roles for CloudWatch Agent
✅ User Data installation for NGINX + CW Agent
✅ Automatic log group creation

🚀 Features
1. EC2 Instance

Amazon Linux 2 instance

NGINX installed and running

CloudWatch Agent installed

2. CloudWatch Metrics

CloudWatch Agent collects memory metrics, including:

MemoryUtilization

mem_used_percent

These metrics appear in:

CloudWatch → Metrics → CWAgent → InstanceId

3. CloudWatch Logs

NGINX access logs are shipped to CloudWatch Logs:

/ec2/nginx/access


Logs include IP, request path, status code, etc.

4. CloudWatch Agent Configuration

The agent is configured through a JSON file that Terraform uploads to:

/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json


It includes both metrics + logs configuration.