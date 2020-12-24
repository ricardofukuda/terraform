output "aws_lb_id"{
  value = aws_lb.nlb.dns_name
}

output "aws_vpc_id" {
  value = aws_vpc.tfvpc.id
}

output "amazonlinux" {
  value = data.aws_ami.amazonlinux
}