resource "aws_db_instance" "wordpress" {
    allocated_storage = 20
    db_name = "wordpress_db"
    engine = "postgres"
    engine_version = "15.3"
    instance_class = "db.t3.micro"
    parameter_group_name = "default.postgres15"
    skip_final_snapshot = true
    username = "{__USER__}"
    password = "{__PASS__}"
    }
