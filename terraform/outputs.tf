output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "frontend_instance_ids" {
  description = "IDs of frontend EC2 instances"
  value       = aws_instance.frontend[*].id
}

output "backend_instance_ids" {
  description = "IDs of backend EC2 instances"
  value       = aws_instance.backend[*].id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}