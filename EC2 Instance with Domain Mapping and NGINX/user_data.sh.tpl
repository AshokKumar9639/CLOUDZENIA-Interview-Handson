#!/bin/bash
set -e
DOMAIN="${domain_name}"
# Update and install packages
yum update -y
amazon-linux-extras install -y nginx1
yum install -y docker git certbot

# Start Docker
systemctl enable --now docker
usermod -a -G docker ec2-user

# Run a Docker container that responds with "Namaste from Container" on port 8080
cat > /home/ec2-user/docker-server.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type","text/plain")
        self.end_headers()
        self.wfile.write(b"Namaste from Container")
if __name__ == "__main__":
    server = HTTPServer(('0.0.0.0', 8080), Handler)
    server.serve_forever()
PY

docker build -t simple-hello - <<'DOCKER'
FROM python:3.11-slim
COPY docker-server.py /app/docker-server.py
WORKDIR /app
EXPOSE 8080
CMD ["python","docker-server.py"]
DOCKER

docker run -d --restart unless-stopped -p 127.0.0.1:8080:8080 simple-hello

# Configure NGINX: two server blocks
cat > /etc/nginx/conf.d/instance.conf <<EOF
server {
    listen 80;
    server_name ec2-instance.${domain_name};

    location / {
        return 200 'Hello from Instance';
        add_header Content-Type text/plain;
    }

    # redirect to https (handled at ALB level too), but for direct instance access:
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 80;
    server_name ec2-docker.${domain_name};

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

systemctl enable --now nginx
systemctl restart nginx

# Attempt to get Let's Encrypt certs using certbot (HTTP challenge).
# IMPORTANT: For this to succeed:
# 1) The domain ec2-instance.<domain> and ec2-docker.<domain> must resolve to this instance's public IP.
# 2) Port 80 must be accessible from internet (temporarily).
# If DNS not propagated, certbot will fail — you may run it manually later.
# certbot will write certificates to /etc/letsencrypt/live/<domain>
#
# Uncomment the next lines if you want the automated attempt at instance creation time:
#
# certbot --nginx -d ec2-instance.${domain_name} -d ec2-docker.${domain_name} --non-interactive --agree-tos -m admin@${domain_name} || true
#
# After certs are created, configure NGINX server blocks to listen 443 and use certs, then reload nginx.
#
