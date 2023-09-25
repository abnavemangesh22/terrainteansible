
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }

  }

}




provider "aws" {
  access_key = "AKIAUVEZDI3EAHYGTPN5"
  secret_key = "UIk232zPNIzRIuFULNgKrX2IV6VYAJlTmpHou5Kp"
  region     = "ap-south-1"

}


# to Create the Key

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myterraform"
  public_key = tls_private_key.example.public_key_openssh
}

output "mykey" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}



# Create Security Group - SSH Traffic
resource "aws_security_group" "vpc-ssh" {
  vpc_id      = aws_vpc.vpc-dev.id
  description = "Dev VPC SSH"

  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Resource-1: Create VPC
resource "aws_vpc" "vpc-dev" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "vpc-dev"
  }
}

# Resource-2: Create Subnets
resource "aws_subnet" "vpc-dev-public-subnet-1" {
  vpc_id                  = aws_vpc.vpc-dev.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# Resource-3: Internet Gateway
resource "aws_internet_gateway" "vpc-dev-igw" {
  vpc_id = aws_vpc.vpc-dev.id
}

# Resource-4: Create Route Table
resource "aws_route_table" "vpc-dev-public-route-table" {
  vpc_id = aws_vpc.vpc-dev.id
}

# Resource-5: Create Route in Route Table for Internet Access
resource "aws_route" "vpc-dev-public-route" {
  route_table_id         = aws_route_table.vpc-dev-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-dev-igw.id
}

# Resource-6: Associate the Route Table with the Subnet
resource "aws_route_table_association" "vpc-dev-public-route-table-associate" {
  route_table_id = aws_route_table.vpc-dev-public-route-table.id
  subnet_id      = aws_subnet.vpc-dev-public-subnet-1.id
}

#instance creation


resource "aws_instance" "my-demo-1" {
  ami           = "ami-0ff30663ed13c2290"
  instance_type = "t2.micro"
  #count                  = "2"
  subnet_id              = aws_subnet.vpc-dev-public-subnet-1.id
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id]
  availability_zone      = "ap-south-1a"
  key_name               = aws_key_pair.generated_key.id
  tags = {
    "env" = "test"
    "OS"  = "amazon"
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname cloudanz.technix.com"]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.example.private_key_pem
    }
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.my-demo-1.public_ip} > inventory"
  }

  provisioner "local-exec" {
    command = "terraform output -raw mykey > mykey.pem; chmod 600 mykey.pem"
  }

  provisioner "local-exec" {
    command = "ansible all -m shell -a 'yum -y install httpd; systemctl restart httpd'"
  }

}

output "myip" {
  value = aws_instance.my-demo-1.public_ip
}
