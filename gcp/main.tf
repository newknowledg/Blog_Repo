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
}
