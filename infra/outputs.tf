output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the created VPC"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "IDs of public subnets"
}

output "alb_arn" {
  value       = aws_lb.app.arn
  description = "ALB ARN"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "Target group ARN"
}
