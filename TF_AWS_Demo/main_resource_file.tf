
# tf file to create ec2 instances in 2 AWS regions. One instance in pri region + some in sec region

#Get AMI ID from AWS dynamically for both pri & sec regions/ec2

#Get Linux AMI ID using SSM Parameter endpoint in aws primary region
data "aws_ssm_parameter" "sk_ubuntu1804_pri" {
  provider = aws.SK_pri_region
  name     = var.ami_image_ssm_url
}

#Get Linux AMI ID using SSM Parameter endpoint in aws secondary region
data "aws_ssm_parameter" "sk_ubuntu1804_sec" {
  provider = aws.SK_sec_region
  name     = var.ami_image_ssm_url
}

# Put/Create SSH key pair id (its also an AWS resource for tf) in aws regions
#Please create SSH key pair seperately before using it here in this file 

#1.Create key-pair for logging into EC2 in aws primary region
resource "aws_key_pair" "pri-key" {
  provider   = aws.SK_pri_region
  key_name   = "sk_key"
  public_key = file("sk_pub_key")
}

#2.Create key-pair for logging into EC2 in aws secondary region
resource "aws_key_pair" "sec-key" {
  provider   = aws.SK_sec_region
  key_name   = "sk_key"
  public_key = file("sk_pub_key")
}

# Create VPCs - One in each region
resource "aws_vpc" "sk_vpc_pri" {
  cidr_block = var.pri_vpc_cidr
  provider   = aws.SK_pri_region
  tags = {
    Name = "sk_vpc_pri_aws"
  }
}

resource "aws_vpc" "sk_vpc_sec" {
  cidr_block = var.sec_vpc_cidr
  provider   = aws.SK_sec_region
  tags = {
    Name = "sk_vpc_sec_aws"
  }
}

# Create subnets - One in each region
resource "aws_subnet" "sk_subnet_pri" {
  provider          = aws.SK_pri_region
  vpc_id            = aws_vpc.sk_vpc_pri.id
  cidr_block        = var.pri_vpc_subnet
  availability_zone = var.AZ_pri_vpc
}

resource "aws_subnet" "sk_subnet_sec" {
  provider          = aws.SK_sec_region
  vpc_id            = aws_vpc.sk_vpc_sec.id
  cidr_block        = var.sec_vpc_subnet
  availability_zone = var.AZ_sec_vpc
}

# Create Internet GWs - One in each region
resource "aws_internet_gateway" "igw_pri" {
  provider = aws.SK_pri_region
  vpc_id   = aws_vpc.sk_vpc_pri.id
}

resource "aws_internet_gateway" "igw_sec" {
  provider = aws.SK_sec_region
  vpc_id   = aws_vpc.sk_vpc_sec.id
}

# Create routing table - One in each region
resource "aws_route_table" "rtb_public_pri" {
  provider = aws.SK_pri_region
  vpc_id   = aws_vpc.sk_vpc_pri.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_pri.id
  }
}

resource "aws_route_table" "rtb_public_sec" {
  provider = aws.SK_sec_region
  vpc_id   = aws_vpc.sk_vpc_sec.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_sec.id
  }
}

# Point routes to internet - One in each region
resource "aws_route_table_association" "rta_subnet_public_pri" {
  provider       = aws.SK_pri_region
  subnet_id      = aws_subnet.sk_subnet_pri.id
  route_table_id = aws_route_table.rtb_public_pri.id
}

resource "aws_route_table_association" "rta_subnet_public_sec" {
  provider       = aws.SK_sec_region
  subnet_id      = aws_subnet.sk_subnet_sec.id
  route_table_id = aws_route_table.rtb_public_sec.id
}

# Create security group for allowing ssh access to ec2s and ec2 access to internet
# AWS by default allows all traffic outside but its disabled in TF so has to be explicitly stated
#Create security group in aws primary region
resource "aws_security_group" "sk_sg_pri_tf" {
  provider = aws.SK_pri_region
  name     = "sk-sg-pri-aws"
  vpc_id   = aws_vpc.sk_vpc_pri.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  # -1 for protocols in TF means "all" protocols.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create security group in aws secondary region
resource "aws_security_group" "sk_sg_sec_tf" {
  provider = aws.SK_sec_region
  name     = "sk-sg-sec-aws"
  vpc_id   = aws_vpc.sk_vpc_sec.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create instances. Use the ami ID's from ssm parameter data
#Create EC2 in aws primary region
resource "aws_instance" "sk_pri_ec2" {
  provider = aws.SK_pri_region
  ami      = data.aws_ssm_parameter.sk_ubuntu1804_pri.value
  #ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.pri-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sk_sg_pri_tf.id]
  subnet_id                   = aws_subnet.sk_subnet_pri.id
  tags = {
    Name = "sk_primary_ec2"
  }
}

#Create EC2 in aws secondary region
resource "aws_instance" "sk_sec_ec2" {
  provider = aws.SK_sec_region
  count    = var.workers-count
  ami      = data.aws_ssm_parameter.sk_ubuntu1804_sec.value
  #ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.sec-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sk_sg_sec_tf.id]
  subnet_id                   = aws_subnet.sk_subnet_sec.id
  tags = {
    Name = join("_", ["sk_secondary_ec2", count.index + 1])
  }
  depends_on = [aws_instance.sk_pri_ec2]
}

###########################################################################
# THE END
###########################################################################
