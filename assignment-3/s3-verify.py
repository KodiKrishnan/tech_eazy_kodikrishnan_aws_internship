import boto3

ROLE_ARN = "arn:aws:iam::Acc_ID:role/s3_readonly"
SESSION_NAME = "readonly-session"
BUCKET_NAME = "ec2-logs-kodi-20250610"

# Assume the role
sts_client = boto3.client("sts")
assumed_role = sts_client.assume_role(
    RoleArn=ROLE_ARN,
    RoleSessionName=SESSION_NAME
)

creds = assumed_role["Credentials"]

# Create S3 client with temporary credentials
s3_client = boto3.client(
    "s3",
    aws_access_key_id=creds["AccessKeyId"],
    aws_secret_access_key=creds["SecretAccessKey"],
    aws_session_token=creds["SessionToken"]
)

# List objects in the logs folder
response = s3_client.list_objects_v2(Bucket=BUCKET_NAME, Prefix="logs/")
for obj in response.get("Contents", []):
    print(obj["Key"])
