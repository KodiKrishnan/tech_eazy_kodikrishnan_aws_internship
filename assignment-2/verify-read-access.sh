#!/bin/bash

# Replace with your role ARN and external ID (if any)
ROLE_ARN="arn:aws:iam::ACC_ID:role/s3_readonly"
SESSION_NAME="readonly-session"

# Assume the role
CREDENTIALS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --output json)

# Extract temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# List bucket contents (replace with your actual bucket name)
BUCKET_NAME="ec2-logs-kodi-20250610"
aws s3 ls s3://$BUCKET_NAME/logs/ --recursive
