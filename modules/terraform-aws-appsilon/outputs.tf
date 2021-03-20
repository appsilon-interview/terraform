output "vpc" {
  description = "VPC created to hold appsilon resources"
  value       = aws_vpc.appsilon
}

output "private_subnets" {
  description = "Private subnets created for RDS within the VPC, each in a different AZ"
  value       = aws_subnet.appsilon_private
}

output "public_subnets" {
  description = "Public subnets created for appsilon within the VPC, each in a different AZ"
  value       = aws_subnet.appsilon_public
}

output "ecs_security_group" {
  description = "Security group controlling access to the ECS tasks"
  value       = aws_security_group.appsilon_ecs
}
