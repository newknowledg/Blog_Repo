provider "google" {
    project = "feisty-proton-401321"
    credentials = "${{ secrets.GCP_SA_KEY }}"
    region = "us-central1"
    zone = "us-central1-c"
}

resource "google_compute_instane" "wordpress" {
    name = "wordpress_instance"
    machine_type = "e2-micro"
    zone = "us-central1-a"
    allow_stopping_for_update = true

    boot_disk{
        initialize_params{
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = default
        access_config{
            //necessary even empty
        }
    }
}
