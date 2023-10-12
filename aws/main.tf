resource "aws_security_group" "allow_external" {
    name = "allow_external"

    ingress {
        from_port = 3306
        to_prot = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_db_instance" "wordpress" {
    allocated_storage = 20
    db_name = "wordpress_db"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    parameter_group_name = "default.mysql5.7"
    skip_final_snapshot = true
    identifier = "wordpress"
    storage_encrypted = true
    publicly_accessible = true
    backup_retention_period = 7
    delete_automated_backups = true
    vpc_security_group_ids = [aws_security_group.allow_external.id]
    username = "{__USER__}"
    password = "{__PASS__}"
    }
