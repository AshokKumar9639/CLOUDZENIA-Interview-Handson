# GitHub Actions: Build and Deploy Custom Microservice to AWS ECS & ECR

This repository contains a GitHub Actions workflow (`.github/workflows/deploy.yml`) that automates the process of building a Docker image for a custom microservice, pushing it to **Amazon ECR**, and deploying it to an **Amazon ECS** service.

---

## Workflow Overview

The workflow triggers on every push to the `main` branch. It performs the following steps:

1. **Checkout Code**  
   The repository code is checked out using the `actions/checkout` action.

2. **Configure AWS Credentials**  
   AWS credentials are loaded from GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) using the `aws-actions/configure-aws-credentials` action.

3. **Login to Amazon ECR**  
   Logs into Amazon Elastic Container Registry (ECR) so that the Docker image can be pushed.

4. **Build Docker Image**  
   Builds a Docker image from the repository's Dockerfile and tags it with the ECR registry URI.

5. **Push Docker Image to ECR**  
   Pushes the Docker image to the specified ECR repository.

6. **Deploy to ECS**  
   - Registers a new ECS task definition with the updated image.
   - Forces a new deployment of the ECS service to use the new image.

---

## Prerequisites

Before using this workflow, ensure the following:

- **AWS Setup**
  - ECS cluster and service already exist.
  - ECR repository is created for the microservice.
  - IAM user/role with permissions for ECS, ECR, and CloudWatch.
- **GitHub Secrets**
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  
- **Dockerfile**
  - Ensure your repository contains a `Dockerfile` for building the microservice image.

---

## Workflow File Location

```text
.github/workflows/deploy.yml
