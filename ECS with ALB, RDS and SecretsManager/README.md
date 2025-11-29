CloudZenia Interview — Hands-On Challenge

This repository contains the complete solution for the CloudZenia Hands-On Interview Challenge, which tests the ability to design, provision, automate, and document AWS infrastructure using Terraform, ECS, EC2, RDS, Secrets Manager, ALB, GitHub Actions, and optional S3 + CloudFront.

🧭 Objective

Build two separate infrastructures using Terraform and post-deployment AWS configurations:

ECS + ALB + RDS + Secrets Manager Setup

EC2 Instances with NGINX, Docker, Domain Mapping, SSL, and ALB

Document the approach, provide endpoints, share code, and ensure all resources run successfully.

🚀 Challenge 1 — ECS with ALB, RDS, Secrets Manager
1️⃣ Infrastructure Overview

This setup deploys:

ECS Cluster in private subnets

WordPress container

Custom Node.js Microservice (“Hello from Microservice”)

RDS (MySQL/Postgres) for WordPress

Secrets Manager for database credentials

Application Load Balancer with HTTPS enforced

Domain Mapping

wordpress.<domain>

microservice.<domain>

Auto Scaling based on CPU & Memory

2️⃣ ECS Requirements
✔ ECS Cluster

Runs in private subnets

ECS Service deploys:

WordPress container (Docker Hub)

Custom Node.js microservice

Auto Scaling configured on:

CPU

Memory

✔ Node.js Microservice

Responds with:

Hello from Microservice

✔ Dockerfile

Included in repository (as required).

3️⃣ RDS Requirements

Select appropriate DB instance type for WordPress

Create a custom DB user + password

Automatic backups enabled

RDS deployed in private subnets

Credentials stored in Secrets Manager

4️⃣ Secrets Manager

Stores RDS:

Username

Password

Endpoint

ECS tasks fetch these via task role + execution role.

5️⃣ IAM Requirements

ECS Task IAM Role with permission to read secrets

Least privilege security groups

DB SG allows only ECS SG inbound

6️⃣ ALB & Domain Mapping

ALB deployed in public subnets

Listener: HTTPS only

HTTP → HTTPS redirection

Domain Names:

wordpress.<domain>

microservice.<domain>

🚀 Challenge 2 — EC2 with Domain Mapping, Docker, NGINX
1️⃣ EC2 Requirements

Deploy 2 EC2 instances in private subnets

Attach Elastic IPs

Domain Names:

ec2-docker1.<domain>

ec2-docker2.<domain>

ec2-instance1.<domain>

ec2-instance2.<domain>

2️⃣ ALB for EC2

ALB in public subnets

HTTPS-only access

Domain Mapping:

ec2-alb-docker.<domain>

ec2-alb-instance.<domain>

3️⃣ Docker Setup

Run container responding with:

Namaste from Container


on port 8080.

4️⃣ NGINX Configuration

Domain-based routing:

✔ ec2-instance.<domain>

Serve plain text:

Hello from Instance

✔ ec2-docker.<domain>

NGINX reverse-proxy to Docker container on port 8080.

5️⃣ SSL / TLS with Let’s Encrypt

Use Certbot

Configure HTTPS

Redirect HTTP → HTTPS

📊 Challenge 3 — Observability
✔ EC2 Metrics

Install CloudWatch Agent

Publish RAM utilization

✔ EC2 Logs

Push NGINX access logs to CloudWatch Logs

🛠 Challenge 4 — GitHub Actions (CI/CD)
Requirements:

Microservice stored in GitHub repository

GitHub Actions should:

Build Docker image

Push to ECR

Deploy to ECS

Workflow file must be included.

🌐 (Optional) Challenge 5 — S3 Static Site + CDN

If implemented:

S3 static site → static-s3.<domain>

CloudFront CDN

Geo-restriction

Lambda@Edge for SEO headers

📦 Submission Requirements
✔ Terraform Code

All scripts + reusable modules

Task definitions, service definitions, ALB config, etc.

✔ GitHub Actions Workflow

Provide repository link or make it public

✔ Documentation (this file)

Include:

Architecture explanation

Instructions

Endpoints

✔ Running Endpoints

Ensure services remain available 48 hrs post-submission.

✔ Optional Video

< 3 minutes demo

⏳ Deadline

48 hrs to complete after starting

⚠ Important Notes

Use your own AWS account

Stay within Free Tier

Costs are your responsibility

Clean up resources after evaluation

Use free subdomains if needed