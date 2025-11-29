# Upload CloudWatch Config + Start CloudWatch Agent

resource "null_resource" "cw_agent_setup" {
  depends_on = [aws_instance.observability]

  connection {
    host        = aws_instance.observability.public_ip
    user        = "ec2-user"
    private_key = file("<path-to-private-key.pem>")
  }

  provisioner "file" {
    source      = "cloudwatch-agent-config.json"
    destination = "/tmp/cloudwatch-agent-config.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "sudo systemctl stop amazon-cloudwatch-agent",
      "sudo systemctl start amazon-cloudwatch-agent"
    ]
  }
}
