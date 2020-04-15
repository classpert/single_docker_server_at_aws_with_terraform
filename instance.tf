provider "aws" {}

resource "aws_instance" "docker_server" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.docker_group.name]
  key_name        = aws_key_pair.deployer.key_name

  connection {
    host        = aws_instance.docker_server.public_ip
    user        = "ubuntu"
    private_key = file("./keys/developer_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo apt-key fingerprint 0EBFCD88",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\"",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl enable docker",
      "mkdir -p /home/ubuntu/certificates"
    ]
  }

  provisioner "local-exec" {
    command = "REMOTE_IP=${aws_instance.docker_server.public_ip} make server_credentials"
  }

  provisioner "file" {
    source      = "keys/ca.pem"
    destination = "/home/ubuntu/certificates/ca.pem"
  }

  provisioner "file" {
    source      = "keys/server-cert.pem"
    destination = "/home/ubuntu/certificates/server-cert.pem"
  }

  provisioner "file" {
    source      = "keys/server-key.pem"
    destination = "/home/ubuntu/certificates/server-key.pem"
  }

  provisioner "file" {
    source      = "config/docker.systemd"
    destination = "/home/ubuntu/docker.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R -v 0400 /home/ubuntu/certificates",
      "sudo chown -R root:root /home/ubuntu/certificates",
      "sudo chmod 0644 /home/ubuntu/docker.service",
      "sudo chown root:root /home/ubuntu/docker.service",
      "sudo mv /home/ubuntu/docker.service /lib/systemd/system/docker.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart docker"
    ]
  }

  tags = {
    Name = "docker-service"
  }
}
