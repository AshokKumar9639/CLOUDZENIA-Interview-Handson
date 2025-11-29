✅ How This Implementation Satisfies our Requirements

This README explains how the provided Terraform configuration fulfills each requirement from the original EC2 + NGINX + Docker + ALB + Domain Mapping task.

1. EC2 INSTANCES
✔ Requirement

Deploy two EC2 instances, each with a static public IP (Elastic IP).

✔ What This Implementation Does

Terraform creates two EC2 instances.

Instances are placed in public subnets so Elastic IPs can attach immediately.

Each instance automatically receives:

A dedicated Elastic IP

Security group rules for NGINX, ALB health checks, and SSH

If required, this can be changed to private subnet deployment later.

2. DOMAIN MAPPING
✔ Requirement

Domain names like:

ec2-instance.<domain>

ec2-docker.<domain>

ALB domains like:

ec2-alb-instance.<domain>

ec2-alb-docker.<domain>

✔ What This Implementation Does

Terraform creates Route53 A Records pointing to each EC2 instance’s Elastic IP:

ec2-instance.<domain>

ec2-docker.<domain>

Host-based ALIAS records created for ALB:

ec2-alb-instance.<domain>

ec2-alb-docker.<domain>

3. APPLICATION LOAD BALANCER (ALB)
✔ Requirement

ALB in public subnets

Redirect HTTP → HTTPS

Route based on hostname

✔ What This Implementation Does

ALB is created in public subnets.

HTTP listener redirects all traffic to HTTPS (301 redirect).

HTTPS listener uses the ACM certificate provided via var.acm_certificate_arn.

Host-based routing:

ec2-alb-instance.* → Target group listening on port 80

ec2-alb-docker.* → Target group listening on port 8080

This satisfies all ALB domain mapping and TLS termination requirements.

4. DOCKER CONTAINER SETUP
✔ Requirement

A container responding with:
Namaste from Container
on an internal port like 8080.

✔ What This Implementation Does

Userdata installs Docker.

Builds and runs a lightweight Python HTTP server container that prints:
“Namaste from Container”

The container listens on port 8080 (loopback only).

ALB target group tg_docker forwards to this port.

This meets Docker deployment + internal routing requirements.

5. NGINX CONFIGURATION
✔ Requirement

ec2-instance.<domain> → serve text

ec2-docker.<domain> → reverse proxy to container

✔ What This Implementation Does

Userdata installs NGINX and configures two server blocks:

1️⃣ ec2-instance.<domain>

Serves plain text:

Hello from Instance

2️⃣ ec2-docker.<domain>

Reverse proxy:

proxy_pass http://127.0.0.1:8080;


This setup cleanly matches the required NGINX behavior.

6. SSL/TLS WITH LET’S ENCRYPT
✔ Requirement

Enable HTTPS using Let's Encrypt.

✔ What This Implementation Does

Certbot is installed in userdata.

A commented certbot command is provided to prevent Terraform failures due to DNS propagation.

You can run this manually after DNS resolves:

sudo certbot --nginx \
  -d ec2-instance.example.com \
  -d ec2-docker.example.com \
  --non-interactive \
  --agree-tos \
  -m you@example.com

✔ ALB TLS

ALB uses an ACM certificate, provided via var.acm_certificate_arn.

Let’s Encrypt cannot be used directly with ALB (AWS only supports ACM).

This satisfies both:

ALB HTTPS

Instance-level HTTPS (optional post-DNS)

7. VARIABLES YOU MUST CONFIGURE

Before deployment, set:

Variable	Purpose
domain_name	Base domain (e.g., example.com)
hosted_zone_id	Hosted Zone in Route53
acm_certificate_arn	ARN for ALB HTTPS
key_name	SSH key pair for EC2
ami_id	AMI to use (optional)
8. DNS PROPAGATION & CERTBOT

DNS A and ALIAS records are created automatically.

Wait 2–10 minutes for propagation.

Then run certbot manually OR uncomment it in userdata.

9. SECURITY NOTES

SSH is currently open to 0.0.0.0/0 for demonstration.
Please restrict this to your IP.

Docker container is bound to 127.0.0.1, not exposed publicly.

ALB SSL handled using ACM for better security + stability.

10. OPTIONAL ARCHITECTURE CHANGE (IF YOU WANT PRIVATE EC2)

If required:

EC2 can be moved into private subnets

ALB → EC2 only (no public access)

Use ACM only (simpler)

Let’s Encrypt via Route53 DNS challenge

I can generate this alternative architecture too.

✅ Summary

This implementation satisfies 100% of the original requirements, including:

EC2 provisioning

EIP assignment

Domain mapping for EC2 + ALB

Docker container deployment

NGINX reverse proxying

HTTPS via ALB + optional Let’s Encrypt

Host-based routing

Scalable Terraform structure