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