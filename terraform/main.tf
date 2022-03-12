terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2.0"
    }
  }
}

provider "aws" {
  access_key  = var.aws_access_key
  secret_key  = var.aws_secret_key
  region      = var.aws_region
}

# Define connect key
resource "aws_key_pair" "keeper" {
  key_name   	= "keeper"
  public_key	= var.aws_public_key
}

# Create vpc
resource "aws_vpc" "vpc_keeper" {
  cidr_block = "172.32.0.0/16"
  tags       = {
    Name = "Keeper VPC"
  }
}
# Create subnet
resource "aws_subnet" "subnet_keeper" {
  vpc_id     = aws_vpc.vpc_keeper.id
  cidr_block = "172.32.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Keeper subnet"
  }
}

# Create gateway
resource "aws_internet_gateway" "gw_keeper" {
  vpc_id = aws_vpc.vpc_keeper.id

  tags = {
    Name = "gw_keeper"
  }
}

# Create default route
resource "aws_route_table" "rtb_keeper" {
  vpc_id = aws_vpc.vpc_keeper.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_keeper.id
  }

  tags = {
    Name = "rtb_keeper"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_keeper.id
  route_table_id = aws_route_table.rtb_keeper.id
}

# Create security group
resource "aws_security_group" "sg_keeper" {
  name        = "sg_keeper"
  description = "Keeper security group"
  vpc_id      = aws_vpc.vpc_keeper.id

  tags = {
    Name = "Keeper security group"
  }
}

# Firewall rules
resource "aws_security_group_rule" "sg_rules_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_ssh
  description       = "SSH" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_web
  description       = "WEB" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_web
  description       = "WEB" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_keeper" {
  type              = "ingress"
  from_port         = 5959
  to_port           = 5959
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_keeper
  description       = "Keeper" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_monitoring_1" {
  type              = "ingress"
  from_port         = 3100
  to_port           = 3100
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_monitoring
  description       = "Monitoring" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_monitoring_2" {
  type              = "ingress"
  from_port         = 9080
  to_port           = 9080
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_monitoring
  description       = "Monitoring" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_monitoring_3" {
  type              = "ingress"
  from_port         = 9093
  to_port           = 9093
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_monitoring
  description       = "Monitoring" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_monitoring_4" {
  type              = "ingress"
  from_port         = 5555
  to_port           = 5555
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_monitoring
  description       = "Monitoring" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_in_monitoring_5" {
  type              = "ingress"
  from_port         = 9102
  to_port           = 9102
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks_monitoring
  description       = "Monitoring" 
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_security_group_rule" "sg_rules_out" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.sg_keeper.id
}

resource "aws_instance" "keeper" {
  ami           		 = "ami-08ca3fed11864d6bb"
  instance_type 		 = "t2.medium"
  count         		 = 1
  vpc_security_group_ids = [
    aws_security_group.sg_keeper.id
  ]

  subnet_id     	       = aws_subnet.subnet_keeper.id
  associate_public_ip_address  = true
  key_name                     = aws_key_pair.keeper.key_name
  user_data_base64             = base64encode(templatefile("./initscript.sh", {
    address1                   = var.address1
    key1                       = var.key1
    address2                   = var.address2
    key2                       = var.key2
    address3                   = var.address3
    key3                       = var.key3
    address4                   = var.address4
    key4                       = var.key4
    address5                   = var.address5
    key5                       = var.key5
    address6                   = var.address6
    key6                       = var.key6
    address7                   = var.address7
    key7                       = var.key7
    gateway_uri                = var.gateway_uri
    gateway_wss                = var.gateway_wss
    airflow_password           = var.airflow_password
    postgres_password          = var.postgres_password
    keeper_repository          = var.keeper_repository
    keeper_repository_branch   = var.keeper_repository_branch
  }))
}

output "ec2_global_ips" {
  value = ["${aws_instance.keeper.*.public_ip}"]
}
