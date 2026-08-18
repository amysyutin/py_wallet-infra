resource "aws_db_subnet_group" "this" {
    name = "${var.name_prefix}-rds"
    subnet_ids = var.subnet_ids

    tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds"
        }
    )
}

resource "aws_security_group" "this" {
    name = "${var.name_prefix}-rds"
    description = "Allow PostgreSQL from the app security group"
    vpc_id = var.vpc_id

    ingress {
        description = "PostgreSQL from allowed security group"
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [var.allowed_security_group_id] 
    }

    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds"
        }
    )
}

resource "random_password" "master" {
    length = 20
    special = true
    override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "this" {
    identifier = "${var.name_prefix}-postgres"

    engine = "postgres"
    engine_version = "16"
    instance_class = var.instance_class

    db_name = var.db_name
    username = var.username
    password = random_password.master.result

    allocated_storage = var.allocated_storage
    storage_encrypted = true
    
    db_subnet_group_name = aws_db_subnet_group.this.name
    vpc_security_group_ids = [aws_security_group.this.id]
    publicly_accessible = false

    skip_final_snapshot = true
    deletion_protection = false
    backup_retention_period = 0

    tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-postgres"
        }
    )
}

