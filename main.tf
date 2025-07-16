terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_security_group" "fastapi_sg" {
  name        = "fastapi-sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "fastapi_server" {
  ami             = "ami-053b0d53c279acc90"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.fastapi_sg.name]
  associate_public_ip_address = true
  user_data = file("user_data.sh")

#   user_data = <<-EOF
#   #!/bin/bash
#   apt-get update -y
#   apt-get install -y python3-pip
#   pip3 install "fastapi[all]" uvicorn

#   cat > /home/ubuntu/main.py << EOL
# from fastapi import FastAPI

# app = FastAPI()

# @app.get("/")
# def read_root():
#     return {"Hello": "World"}
# EOL

#   cd /home/ubuntu
#   nohup uvicorn main:app --host 0.0.0.0 --port 80
#    &
# EOF


  tags = {
    Name = "FastAPI-Server"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "id_rsa"
  public_key = file("~/.ssh/id_rsa.pub")
}

output "instance_public_ip" {
  value = aws_instance.fastapi_server.public_ip
}