output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.this.arn
}

output "app_url" {
  value = "https://${aws_cloudfront_distribution.this.domain_name}"
}