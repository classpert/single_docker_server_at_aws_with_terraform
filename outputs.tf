output "docker_server_ip" {
  value = aws_instance.docker_server.public_ip
}

output "docker_instance_id" {
  value = aws_instance.docker_server.id
}
