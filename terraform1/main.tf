# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance


resource "aws_instance" "backend" {
  ami           = "ami-0885b1f6bd170450c" #ubuntu 20.04 LTS
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ssh.ricardo-key
  #key_name = aws_key_pair.backend_key.ricardo_key
  availability_zone = "us-east-1a" #public subnet

  security_groups = [
    aws_security_group.backend.name
  ]

  tags = {
    Name = "backend-${terraform.workspace}"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "backend" {
  name        = "backend-${terraform.workspace}"
  description = "backend security group"

  ingress {
    description = "ssh"
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

/*resource "aws_key_pair" "backend_key"{
  key_name = "ricardo_key"
  public_key = "~/ricardo-key.pub"
}*/

resource "null_resource" "prov_null" {
  triggers = {
    public_ip = aws_instance.backend.public_ip
  }

  connection {
    host        = aws_instance.backend.public_ip
    private_key = file("~/.ssh/ricardo.pem")
    user        = "ubuntu"
  }

  provisioner "remote-exec" {
    //inline = ["sudo apt-get update", "sudo apt-get install openjdk-8-jre -y", "sudo apt-get -y install python"]
    inline = []
  }
}