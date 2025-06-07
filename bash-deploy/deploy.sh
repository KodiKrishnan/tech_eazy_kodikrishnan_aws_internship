#!/bin/bash

set -e

STAGE=$1
if [ -z "$STAGE" ]; then
  echo "Usage: $0 <Stage> ( Dev or Prod)"
  exit 1
fi

CONFIG_FILE="config/${STAGE,,}_config.env"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file $CONFIG_FILE not found!"
  exit 1
fi

# Load config
source "$CONFIG_FILE"

# Spin up EC2
echo "Creating EC2 instance of type $INSTANCE_TYPE in region $AWS_REGION..."

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP" \
  --subnet-id "$SUBNET_ID" \
  --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$STAGE-EC2}]" \
  --user-data file://user-data.sh \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance $INSTANCE_ID is running at IP $PUBLIC_IP"

# Wait for app to start and test
echo "Waiting for app to be accessible..."
sleep 120

HTTP_RESPONSE=$(curl -s -o response.txt -w "%{http_code}" "http://$PUBLIC_IP")

if [ "$HTTP_RESPONSE" -eq 200 ]; then
  echo "✅ App is reachable at http://$PUBLIC_IP (HTTP 200)"
  echo "🔹 Response content:"
  cat response.txt
else
  echo "❌ App is not reachable or returned error (HTTP $HTTP_RESPONSE)"
  echo "🔹 Partial response (if any):"
  cat response.txt
fi

# Schedule shutdown
echo "Scheduling instance stop in $SHUTDOWN_MIN minutes..."
(sleep "$((SHUTDOWN_MIN * 60))" && \
  aws ec2 stop-instances --instance-ids "$INSTANCE_ID") &

echo "Script finished."
