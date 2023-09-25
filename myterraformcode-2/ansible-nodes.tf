resource "aws_instance" "ansible-nodes" {
  ami             = "ami-0ff30663ed13c2290"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.generated_key.id
  count           = 2
  security_groups = [aws_security_group.vpc-ssh.id]
  subnet_id       = aws_subnet.vpc-dev-public-subnet-1.id
  user_data       = file("node.sh")
  tags = {
    Name = "ansible-node-${count.index + 1}"
  }
}