

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myterraformkey"
  public_key = tls_private_key.example.public_key_openssh
}


resource "aws_instance" "my-demo-anz" {
  ami           = "ami-0ff30663ed13c2290"
  instance_type = "t2.micro"
  count = 4
  key_name      = aws_key_pair.generated_key.id
  vpc_security_group_ids = [ aws_security_group.vpc-ssh.id ]
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<h1>Welcome to Terraform</h1>" > /var/www/html/index.html
    EOF
}

output "mykey" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}


resource "aws_security_group" "vpc-ssh" {
  vpc_id = "vpc-061415da775675ff7"
  ingress {
    description = "allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "this is outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}