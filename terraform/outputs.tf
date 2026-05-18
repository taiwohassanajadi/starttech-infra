output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}
output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}
output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}
output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "backend_log_group_name" {
  value = aws_cloudwatch_log_group.backend.name
}
output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}