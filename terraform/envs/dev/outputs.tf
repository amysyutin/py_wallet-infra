output "instance_id" {
    description = "EC2 instance ID"
    value = aws_instance.this.id
}

output "instance_public_ip" {
    description = "EC2 public IP"
    value = aws_instance.this.public_ip
}

output "instance_private_ip" {
    description = "EC2 private IP"
    value = aws_instance.this.private_ip
}

output "security_group_id" {
    description = "Security Group ID for EC2 SSH access"
    value = aws_security_group.ec2_ssh.id
}

output "subnet_id" {
    description = "Subnet ID where EC2 is launched"
    value = aws_instance.this.subnet_id
}

output "ssh_command" {
    description = "SSH command to connect to EC2 instance"
    value = "ssh -i ~/.ssh/aws/pywallet-dev-key.pem ubuntu@${aws_instance.this.public_ip}"
}

