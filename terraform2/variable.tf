// Here you are just defining and configuring the default.
// Usually to override the value, you need to edit terraform.tfvars
variable "aws_launchconfig_name" {
  description = "aws launch config"
  default = "aws_launch"
  type = string
}

variable "aws_image_name" {
  description = "amazon linux image"
  default = "ami-0885b1f6bd170450c"
  type = string
}

variable "aws_instance_type" {
  description = "amazon instance type"
  default = "t2.nano"
  type = string
}