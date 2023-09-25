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
  user_data = file("installmaster.sh")

  provisioner "remote-exec" {
    inline = [
      "echo '[ansible]' >> /home/ec2-user/inventory",
      "echo 'ansible-engine ansible_host=${aws_instance.my-demo-1.private_ip} ansible_connection=local' >> /home/ec2-user/inventory",
      "echo 'node1 ansible_host=${aws_instance.ansible-nodes[0].private_ip}' >> /home/ec2-user/inventory",
      "echo 'node2 ansible_host=${aws_instance.ansible-nodes[1].private_ip}' >> /home/ec2-user/inventory",
      "echo '' >> /home/ec2-user/inventory",
      "echo '[all:vars]' >> /home/ec2-user/inventory",
      "echo 'ansible_user=devops' >> /home/ec2-user/inventory",
      "echo 'ansible_password=devops' >> /home/ec2-user/inventory",
      "echo 'ansible_connection=ssh' >> /home/ec2-user/inventory",
      "echo '#ansible_python_interpreter=/usr/bin/python3' >> /home/ec2-user/inventory",
      "echo 'ansible_ssh_private_key_file=/home/devops/.ssh/id_rsa' >> /home/ec2-user/inventory",
      "echo \"ansible_ssh_extra_args=' -o StrictHostKeyChecking=no -o PreferredAuthentications=password '\" >> /home/ec2-user/inventory",
      "echo '[defaults]' >> /home/ec2-user/ansible.cfg",
      "echo 'inventory = ./inventory' >> /home/ec2-user/ansible.cfg",
      "echo 'host_key_checking = False' >> /home/ec2-user/ansible.cfg",
      "echo 'remote_user = devops' >> /home/ec2-user/ansible.cfg",
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.example.private_key_pem
    }
  }

  provisioner "file" {
    source      = "engine-config.yaml"
    destination = "/home/ec2-user/engine-config.yaml"
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.example.private_key_pem
    }
  }
  provisioner "remote-exec" {

    inline = [
      "sleep 120; ansible-playbook engine-config.yaml"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.example.private_key_pem
    }
  }

}

output "myip" {
  value = aws_instance.my-demo-1.public_ip
}
