terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

########################
# RANDOM SUFFIX FOR UNIQUE NAMES
########################
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

########################
# KEY PAIR
########################
resource "tls_private_key" "taxi_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "taxi" {
  key_name   = "taxi"
  public_key = tls_private_key.taxi_key.public_key_openssh
}

resource "local_file" "taxi_private_key" {
  content         = tls_private_key.taxi_key.private_key_pem
  filename        = "${path.module}/taxi-key.pem"
  file_permission = "0400"
}
########################
# DEFAULT VPC + SUBNET
########################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################
# SECURITY GROUP
########################
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow required ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
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

########################
# IAM ROLE (FIXES AWS ERROR)
########################
resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.ec2_role.name
}

########################
# S3 BUCKET
########################
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "my-war-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "war-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################
# ECR REPO
########################
resource "aws_ecr_repository" "app_repo" {
  name = "taxi-booking-app"

  image_scanning_configuration {
    scan_on_push = true
  }
}

########################
# EC2 INSTANCES
########################

# ANSIBLE
resource "aws_instance" "ansible" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.taxi.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "ansible"
  }
}

# JENKINS MASTER
resource "aws_instance" "jenkins_master" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.taxi.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "jenkins-master"
  }
}

# JENKINS SLAVE
resource "aws_instance" "jenkins_slave" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.taxi.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "jenkins-slave"
  }
}

########################
# OUTPUTS
########################
output "s3_bucket" {
  value = aws_s3_bucket.artifact_bucket.bucket
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "private_key_path" {
  value = local_file.taxi_private_key.filename
}

output "ansible_ip" {
  value = aws_instance.ansible.public_ip
}

output "jenkins_master_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_ip" {
  value = aws_instance.jenkins_slave.public_ip
}

output "ssh_private_key" {
  value     = tls_private_key.taxi_key.private_key_pem
  sensitive = true
}