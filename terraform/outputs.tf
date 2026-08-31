output "app_server_public_ip" {
  description = "Public IP of the EC2 app server"
  value       = aws_instance.app_server.public_ip
}

output "frontend_url" {
  description = "URL to access the frontend"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "backend_url" {
  description = "URL to access the backend API"
  value       = "http://${aws_instance.app_server.public_ip}:5000/api"
}

output "ecr_backend_repo_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repo_url" {
  value = aws_ecr_repository.frontend.repository_url
}
