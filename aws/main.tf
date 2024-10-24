resource "aws_security_group" "allow_external" {
    name = "allow_external"

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_db_instance" "wordpress" {
    allocated_storage = 20
    db_name = "{__NAME__}"
    engine = "mysql"
    engine_version = "8.0.35"
    ca_cert_identifier = "rds-ca-rsa2048-g1"
    instance_class = "db.t3.micro"
    parameter_group_name = "require-secure-transport"
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

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "{__VPC_ID__}"
  amazon_side_asn = "{__AWS_ASN__}"

  tags = {
    Name = "main"
  }
}

resource "aws_customer_gateway" "main" {
  bgp_asn    = {__GCP_ASN___}
  ip_address = "{__GCP_IP__}"
  type       = "ipsec.1"
  tunnel1_preshared_key = "{__SHARED_SECRET__}"
  tunnel2_preshared_key = "{__SHARED_SECRET__}"
  
  tags = {
    Name = "gcp-info"
  }
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_vpn_connection_route" "gcp" {
  destination_cidr_block = "10.20.0.0/16"
  vpn_connection_id      = aws_vpn_connection.main.id
}
