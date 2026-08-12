output "endpoint" {
    description = "RDS connection endpoint (host:port)"
    value = aws_db_instance.this.endpoint
}

output "port" {
    description = "RDS port"
    value = aws_db_instance.this.port
}

output "db_name" {
    description = "PostgreSQL database name"
    value = aws_db_instance.this.db_name 
}

output "username" {
    description = "Master username"
    value = aws_db_instance.this.username
}

output "password" {
    description = "Master password"
    value = random_password.master.result
    sensitive = true
}

