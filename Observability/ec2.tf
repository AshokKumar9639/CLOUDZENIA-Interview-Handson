# EC2 + Install CloudWatch Agent + NGINX

resource "aws_instance" "observability" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 (modify if needed)
  instance_type = "t3.micro"
  subnet_id     = "<your-subnet-id>"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = "<your-key>"

  user_data = <<EOF
#!/bin/bash
yum update -y

# Install NGINX
amazon-linux-extras install nginx1 -y
systemctl enable nginx
systemctl start nginx

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

EOF

  tags = {
    Name = "Observability-EC2"
  }
}

