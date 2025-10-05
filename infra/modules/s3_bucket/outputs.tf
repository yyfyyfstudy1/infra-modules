output "bucket_id" {
  description = "S3 桶 ID"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 桶 ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "S3 桶域名"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 桶区域域名"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

