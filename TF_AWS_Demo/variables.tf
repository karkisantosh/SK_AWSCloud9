
variable "aws_pri_region" {
  description = "AWS Pri Region as sectected by the user"
  default     = "us-east-1"
}

variable "aws_sec_region" {
  description = "AWS Sec Region as sectected by the user"
  default     = "us-west-2"
}


variable "AZ_pri_vpc" {
  description = "AZ for the subnet in pri VPC"
  default     = "us-east-1a"
}

variable "AZ_sec_vpc" {
  description = "AZ for the subnet in sec VPC"
  default     = "us-west-2a"
}

variable "pri_vpc_cidr" {
  description = "CIDR block for the pri VPC"
  default     = "192.168.10.0/24"
}

variable "sec_vpc_cidr" {
  description = "CIDR block for the sec VPC"
  default     = "192.168.20.0/24"
}

variable "pri_vpc_subnet" {
  description = "Subnet block for the pri VPC subnet"
  default     = "192.168.10.0/25"
}

variable "sec_vpc_subnet" {
  description = "Subnet block for the sec VPC subnet"
  default     = "192.168.20.0/25"
}

variable "instance_ami" {
  description = "Ubuntu server 1804 AMI for aws EC2 instance"
  default     = "ami-0817d428a6fb68645"
}

variable "ami_image_ssm_url" {
  description = "Ubuntu server 1804 AMI image SSM URL"
  default     = "/aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t3.micro"
}

variable "workers-count" {
  type    = number
  default = 2
}

