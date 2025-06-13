# Assignment 3: Automated Java Application Deployment using Terraform and GitHub Actions

## ✅ Overview

This project automates the provisioning and deployment of a Java web application using **Terraform** for infrastructure-as-code (IaC) and **GitHub Actions** for CI/CD. It builds on Assignments 1 and 2 by adding full automation, deployment orchestration, and application health validation.

---

## 🧩 Features

### 1. Infrastructure Provisioning (IaC)

- **Terraform-based provisioning**
  - EC2 Instance (configurable: instance type, stage, etc.)
  - S3 Bucket (for storing logs)
  - IAM Roles and secure instance profile attachment
- **Parameterization**
  - Stage-specific variables via `dev.tfvars`, `prod.tfvars`
  - Fully codified infrastructure components

---

### 2. CI/CD Workflow with GitHub Actions

- Triggered on:
  - Push to `main`
  - Tags: `deploy-dev`, `deploy-prod`
- Dynamic stage detection from tag/branch
- Passes the appropriate tfvars file to Terraform

---

### 3. Application Deployment Automation

- Automatically:
  - Provisions EC2 using Terraform
  - Fetches public IP from Terraform output
  - SSHes into the instance and runs setup & deployment scripts
  - Uploads app logs to S3 using IAM role credentials

---

### 4. Application Health Validation

- GitHub Action polls the public IP of EC2 post-deployment
- Validates if the application responds with HTTP 200 on port 80
- Retries up to 10 times with configurable delay to ensure startup time
- Provides real-time feedback in GitHub Action logs

---

## 🚀 Deployment Instructions

### ✅ GitHub Workflow Triggers

- Push to `main` → deploys to **dev**
- Tag with `deploy-prod` → deploys to **prod**

### ✅ How it works

1. GitHub Action triggers on push/tag.
2. Terraform initializes and applies infrastructure using the correct stage config.
3. Public IP of EC2 is fetched.
4. App is deployed via startup script or SSH.
5. App health is validated (curl to `http://<EC2_IP>:80`)
6. Terraform state is uploaded as artifact.
7. Environment is destroyed using `terraform destroy`.

---

## 🛠 Technologies Used

- Terraform (v1.5.7)
- AWS (EC2, IAM, S3)
- GitHub Actions
- Shell Scripting
- Amazon Linux 2
- Java Web Application

---

## 📁 Directory Structure

```bash
.
├── .github/workflows/
│   └── deploy.yml             # GitHub Action workflow
├── assignment-3/
│   ├── main.tf                # Terraform main configuration
│   ├── variables.tf           # Variable declarations
│   ├── outputs.tf             # Outputs (e.g., instance public IP)
│   ├── dev.tfvars             # Dev environment config
│   ├── prod.tfvars            # Prod environment config
│   ├── user-data.sh           # EC2 startup script
│   └── terraform.tfstate      # Terraform state file (generated)
