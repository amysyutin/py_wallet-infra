data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
        }
}
data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


resource "aws_security_group" "ec2_ssh" {
    name = "${var.project}-${var.environment}-ec2-ssh"
    description = "Allow SSH access from my IP"
    vpc_id = data.aws_vpc.default.id

    ingress {
        description = "SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip_cidr]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags ={
        Name = "${var.project}-${var.environment}-ec2-ssh"
        Project = var.project
        Environment = var.environment
        ManagedBy = "terraform"
        Owner = var.owner
    }
}


module "ec2" {
    source = "../../modules/ec2"

    name = "${var.project}-${var.environment}-ec2"
    ami_id = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    subnet_id = data.aws_subnets.default_vpc.ids[0]
    security_group_ids = [aws_security_group.ec2_ssh.id]
    key_name = var.key_name
    associate_public_ip = true

    tags = {
        Project = var.project
        Environment = var.environment
        ManagedBy = "terraform"
        Owner = var.owner
    }

}