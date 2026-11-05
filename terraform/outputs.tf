output "alb_dns_name" {
  description = "Open this in a browser or curl it, for example http://<value>/api/v1/locations/"
  value       = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  description = "Where to push the Docker image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}
