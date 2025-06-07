# AWS EC2 Java App Deployment with Terraform

## Overview

This project demonstrates automated provisioning of an AWS EC2 instance using Terraform, with the following features:

- ✅ Automatic SSH key pair generation (securely handled by Terraform)
- ✅ Environment-based configuration (Dev, Prod, etc.)
- ✅ Security group setup for SSH and HTTP access
- ✅ User data script to:
  - Install Java 21, Maven, Git, and dependencies
  - Clone and build a Java application from GitHub
  - Run the application
  - Verify site accessibility via the public IP
  - Schedule automatic shutdown of the instance after 15 minutes if the app is running
- 🔐 No AWS secrets or keys in code (credentials are read from environment variables or AWS profiles)
- 📤 Outputs: Public IP and Instance ID

---

## 📁 Directory Structure

```
.
├── dev.tfvars
├── prod.tfvars
├── main.tf
├── variables.tf
├── outputs.tf
├── user-data.sh
└── README.md
```

---

## ✅ Prerequisites

- AWS account (Free Tier is sufficient)
- Terraform v1.2.0 or newer
- AWS CLI configured (`aws configure`)
- Git

---

## 🚀 Usage

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd <your-repo-directory>
```

### 2. Export AWS Credentials

Make sure your AWS credentials are set in your environment (do not hardcode in code):

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

Or use an AWS CLI profile (`aws configure --profile my-profile`).

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Deploy the Infrastructure

**For Dev environment:**

```bash
terraform apply -var-file="dev.tfvars"
```

**For Prod environment:**

```bash
terraform apply -var-file="prod.tfvars"
```

### 5. Access the Application

After deployment, Terraform will output the public IP.

Open `http://<public_ip>` in your browser. If the app is running, you will see a "Successfully Deployed" message.

### 6. Automatic Shutdown

If the application is accessible (HTTP 200), the instance will automatically shut down after 15 minutes to save costs.

### 7. Destroy Resources

When finished, clean up to avoid charges:

```bash
terraform destroy -var-file="dev.tfvars"
```

---

## 🛠️ Customization

- **Environment configs**: Edit `dev.tfvars` or `prod.tfvars` for region, AMI, instance type, etc.
- **User data script**: Modify `user-data.sh` for custom build, deployment, or notification logic.

---

## 🔐 Security Notes

- Never commit your `.pem` private key or AWS credentials to version control.
- The private key is generated and saved locally for SSH access.
- All secrets/credentials should be managed via environment variables or AWS profiles.

---

## 📄 File Descriptions

| File           | Purpose                                                     |
| -------------- | ----------------------------------------------------------- |
| `main.tf`      | Main Terraform configuration (resources, key pair, EC2, SG) |
| `variables.tf` | Input variable definitions                                  |
| `outputs.tf`   | Outputs for public IP and instance ID                       |
| `dev.tfvars`   | Dev environment variables                                   |
| `prod.tfvars`  | Prod environment variables                                  |
| `user-data.sh` | User data script for EC2 bootstrapping and app deployment   |
| `README.md`    | This documentation                                          |

---

## 📚 References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Amazon Linux Extras](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/amazon-linux-ami-basics.html)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

## ✍️ Author

**Kodi Arasan M** [kodikrishnan2307@gmail.com]  07-06-2025

---

Happy DevOps! 🚀
