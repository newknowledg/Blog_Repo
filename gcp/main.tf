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

resource "google_compute_router" "vpn-router" {
  name    = "vpn-route"
  region  = "us-central1"
  network = "wordpress-network"

  bgp {
    asn = "{__GCP_ASN__}"
  }
}
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  region   = "us-central1"
  name     = "ha-vpn"
  network  = google_compute_network.wordpress_net.id
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  name            = "external-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "An externally managed VPN gateway"
  interface {
    id         = 0
    ip_address = "{__AWS_IP1__}"
  }
  
  interface {
    id         = 1
    ip_address = "{__AWS_IP2__}"
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "ha-vpn-tunnel1"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = "{__SHARED_SECRET__}"
  router                          = google_compute_router.vpn-router.id
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name                            = "ha-vpn-tunnel2"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = "{__SHARED_SECRET__}"
  router                          = google_compute_router.vpn-router.id
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = google_compute_router.vpn-router.name
  region     = "us-central1"
  ip_range   = "{__CIDR1__}"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

import {
  id = "projects/{__PROJECT_ID__}/regions/us-central1/addresses/vpn"
  to = google_compute_address.default
}

resource "google_compute_address" "default" {
 name: "vpn" 
}

resource "google_compute_interconnect_attachment" "attachment1" {
  name                     = "test-interconnect-attachment1"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  type                     = "PARTNER"
  router                   = google_compute_router.vpn-router.id
  encryption               = "IPSEC"
  ipsec_internal_addresses = [
    google_compute_address.default.self_link,
  ]
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = google_compute_router.vpn-router.name
  region                    = "us-central1"
  peer_ip_address           = "{__SN1__}"
  peer_asn                  = {__AWS_ASN__}
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = google_compute_router.vpn-router.name
  region     = "us-central1"
  ip_range   = "{__CIDR2__}"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = google_compute_router.vpn-router.name
  region                    = "us-central1"
  peer_ip_address           = "{__SN2__}"
  peer_asn                  = {__AWS_ASN__}
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}
