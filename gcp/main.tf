locals {
    ssh_user = "ansible"
    private_key_path = "ansible.ssh"
}

resource "google_compute_network" "wordpress_net" {
    project  = "{__PROJECT_ID__}"
    name = "wordpress-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "wordpress_subnet" {
    project  = "{__PROJECT_ID__}"
    name = "wordpress-subnet"
    ip_cidr_range = "10.20.0.0/16"
    region = "us-central1"
    network = google_compute_network.wordpress_net.id
}

resource "google_compute_firewall" "wp_fw" {
    project  = "{__PROJECT_ID__}"
    name = "wp-fw"
    network = google_compute_network.wordpress_net.id

    allow {
        protocol = "tcp"
        ports = ["80", "8080", "22", "443", "8443"]
    }

    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "wordpress" {
    project  = "{__PROJECT_ID__}"
    name = "wordpress-instance"
    machine_type = "e2-micro"
    zone = "us-central1-a"
    allow_stopping_for_update = true

    boot_disk{
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = google_compute_network.wordpress_net.id
        subnetwork = google_compute_subnetwork.wordpress_subnet.id
        access_config{
            //necessary even empty
        }
    }
    provisioner "remote-exec" {
        inline = ["echo 'Wait until SSH is ready'"]

        connection {
            type = "ssh"
            user =  local.ssh_user
            private_key = file(local.private_key_path)
            host = google_compute_instance.wordpress.network_interface.0.access_config.0.nat_ip
        }
    }

    provisioner "local-exec" {
        command = "ansible-playbook -i ${google_compute_instance.wordpress.network_interface.0.access_config.0.nat_ip}, --private-key ${local.private_key_path} playbook.yml"
    }
}

resource "google_compute_router" "vpn-route" {
  name    = "vpn-route"
  region  = "us-central1"
  network = "wordpress-network"

  bgp {
    asn = "{__GCP_ASN__}"
  }
}

module "vpn-manage-internal" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.2.0"

  project_id  = "{__PROJECT_ID__}"
  network = "wordpress-network"
  region  = "us-central1"
  gateway_name       = "aws-gcp-vpn"
  tunnel_name_prefix = "aws-gcp-vpn-tunnel"
  shared_secret      = "{__SHARED_SECRET__}"
  tunnel_count       = 2
  vpn_gw_ip          = "{__GCP_IP__}"
  peer_asn           = ["{__AWS_ASN__}"]
  peer_ips           = ["{__AWS_IP1__}", "{__AWS_IP2__}"]

  route_priority = 1000
  remote_subnet  = ["{__SN1__}", "{__SN2__}"]
}
