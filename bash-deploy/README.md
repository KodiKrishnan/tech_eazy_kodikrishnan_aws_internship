# EC2 Auto Deployment Script

## Usage

```bash
./deploy.sh Dev
```

This will:
- Spin up a configured EC2 instance
- Install Java 21(I have installed the Java 21 as techeazy-devops has require 21)
- Clone and deploy the app
- Check if the app is reachable
- Stop the instance after N minutes

## Configuration
Edit `config/dev_config.env` or `prod_config.env` to set:
- Instance type
- AWS Region
- AMI ID
- Key pair
- Subnet & security group
