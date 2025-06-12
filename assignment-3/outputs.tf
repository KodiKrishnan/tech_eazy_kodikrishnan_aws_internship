output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}

output "readonly_role_arn" {
  value = aws_iam_role.s3_readonly.arn
}

