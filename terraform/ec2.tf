data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    # Install docker-compose plugin
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    mkdir -p /opt/auth-project
    cat > /opt/auth-project/docker-compose.yml <<'COMPOSE'
    version: "3.9"
    services:
      mongo:
        image: mongo:7
        restart: unless-stopped
        volumes:
          - mongo-data:/data/db
      backend:
        image: ${aws_ecr_repository.backend.repository_url}:latest
        restart: unless-stopped
        depends_on:
          - mongo
        environment:
          - PORT=5000
          - MONGO_URI=mongodb://mongo:27017/authdb
          - JWT_SECRET=${var.jwt_secret}
        ports:
          - "5000:5000"
      frontend:
        image: ${aws_ecr_repository.frontend.repository_url}:latest
        restart: unless-stopped
        depends_on:
          - backend
        ports:
          - "80:80"
    volumes:
      mongo-data:
    COMPOSE

    cd /opt/auth-project
    docker compose up -d
  EOF
}

data "aws_caller_identity" "current" {}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = local.user_data

  tags = {
    Name = "${var.project_name}-app-server"
  }
}
