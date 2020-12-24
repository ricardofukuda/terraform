terraform {
  /*backend "local" {
    path = "./state/localstate.tfstate"
  }*/

  backend "s3" {
    bucket = "fukudatfstate"
    key = "state.tfstate"
    region = "us-east-1"
    //dynamodb_table = "locktablename" if you are using the state locking
  }
}



// Provides a resource to create a new launch configuration, used for autoscaling groups.
resource "aws_launch_configuration" "aws-launch"{
  name = var.aws_launchconfig_name
  image_id = var.aws_image_name
  instance_type = var.aws_instance_type
  associate_public_ip_address = true
  key_name = "ricardo-key"
  security_groups = [aws_security_group.awsfw.id]
  user_data = <<-EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y httpd
sudo service httpd start
echo '<!doctype html><html><head><title>CONGRATULATIONS!!..You are on your way to become a Terraform expert!</title><style>body {background-color: #1c87c9;}</style></head><body></body></html>' | sudo tee /var/www/html/index.html
echo "<BR><BR>Terraform autoscaled app multi-cloud lab<BR><BR>" >> /var/www/html/index.html
EOF
}

locals{
  ingress_config = [{
    from_port = 80
    to_port = 80
    description = "web port"
    cidr = ["0.0.0.0/0"]
    protocol = "tcp"
  },
  {
    from_port = 22
    to_port = 22
    description = "ssh port"
    cidr = ["0.0.0.0/0"]
    protocol = "tcp"
  }]
}

resource "aws_security_group" "awsfw" {
  name = "aws-fw"
  vpc_id = aws_vpc.tfvpc.id //todo
  /*ingress {
    description = "value"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }

  ingress {
    description = "value"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }*/

  dynamic "ingress"{
    for_each = local.ingress_config
    content{
      description = ingress.value.description
      cidr_blocks = ingress.value.cidr
      from_port = ingress.value.from_port
      protocol = ingress.value.protocol
      to_port = ingress.value.to_port
    }
  }

  egress {
    description = "value"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

resource "aws_autoscaling_group" "tfasg" {
  name = "tf-asg"
  max_size = 2
  min_size = 1
  launch_configuration = aws_launch_configuration.aws-launch.name
  vpc_zone_identifier = [aws_subnet.web1.id,aws_subnet.web2.id]
  target_group_arns = [aws_lb_target_group.pool.arn]

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "tf-ec2VM"
  }
}

resource "aws_lb" "nlb"{
  name = "tf-nlb"
  load_balancer_type = "network"
  enable_cross_zone_load_balancing = true
  subnets = [aws_subnet.web1.id, aws_subnet.web2.id]
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.nlb.arn // Amazon Resource Name (ARN) of the load balancer
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.pool.arn
  }
}

resource "aws_lb_target_group" "pool" {
  name = "web"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.tfvpc.id
}

resource "aws_vpc" "tfvpc"{
  cidr_block = "172.20.0.0/16"

  tags = {
    name = "tf-vpc"
  }
}

resource "aws_subnet" "web1" {
  cidr_block = "172.20.10.0/24"
  vpc_id = aws_vpc.tfvpc.id
  availability_zone = "us-east-1a"

  tags = {
    name = "sub-web1"
  }
}

resource "aws_subnet" "web2" {
  cidr_block = "172.20.20.0/24"
  vpc_id = aws_vpc.tfvpc.id
  availability_zone = "us-east-1b"

  tags = {
    name = "sub-web2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tfvpc.id
  tags = {
    name = "igw"
  }
}

resource "aws_route" "tfroute" {
  route_table_id = aws_vpc.tfvpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}