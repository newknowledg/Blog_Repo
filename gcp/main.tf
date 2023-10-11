locals {
    ssh_user = "ansible"
    private_key_path = "ansible.ssh"
}

resource "google_compute_network" "wordpress_net" {
    project  = "feisty-proton-401321"
    name = "wordpress-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "wordpress_subnet" {
    project  = "feisty-proton-401321"
    name = "wordpress-subnet"
    ip_cidr_range = "10.20.0.0/16"
    region = "us-central1"
    network = google_compute_network.wordpress_net.id
}

resource "google_compute_firewall" "wp_fw" {
    project  = "feisty-proton-401321"
    name = "wp-fw"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["80", "8080", "22"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_service_accounts = ["github@feisty-proton-401321.iam.gserviceaccount.com", "791135505681-compute@developer.gserviceaccount.com"]
}

resource "google_compute_instance" "wordpress" {
    project  = "feisty-proton-401321"
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
        command = "ansible-playbook -i ${google_compute_instance.wordpress.network_interface.0.access_config.0.nat_ip}, private-key ${local.private_key_path} playbook.yml"
    }
}

