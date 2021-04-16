variable "project_id" {}

resource "random_shuffle" "zone" {
  input        = ["us-west1-a", "us-west1-b", "us-west1-c"]
  result_count = 1
}

resource "random_integer" "instance_id_suffix" {
  min = 100000
  max = 999999
}

locals {
    region = "us-west1"
    zone = random_shuffle.zone.result[0]
    instance_name = "geth-${random_integer.instance_id_suffix.id}"
}

provider "google" {
  project = var.project_id
  region  = local.region
  zone    = local.zone
}

resource "google_compute_instance" "geth" {
  name         = "geth-${random_integer.instance_id_suffix.id}"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      size  = 30
      type  = "pd-standard"
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }

  metadata = {
    cos-metrics-enabled    = true
    google-logging-enabled = true
    user-data              = <<EOF
#cloud-config

write_files:
- path: /etc/systemd/system/ethereum.service
  permissions: 0644
  owner: root
  content: |
    [Unit]
    Description=Start a Ethereum client
    Wants=gcr-online.target
    After=gcr-online.target

    [Service]
    Environment="HOME=/var/ethereum"
    ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
    ExecStart=/usr/bin/docker run --rm --name=ethereum -v /var/ethereum:/root -p 8545:8545 -p 30303:30303 ethereum/client-go:latest \
    --ropsten \
    --syncmode "light" \
    --http \
    --http.addr "0.0.0.0" \
    --http.corsdomain '*' \
    --http.api 'personal,eth,net,web3,txpool,miner,debug'
    ExecStop=/usr/bin/docker stop ethereum
    ExecStopPost=/usr/bin/docker rm ethereum

runcmd:
- systemctl daemon-reload
- systemctl start ethereum.service
EOF
  }
}

output "project_id" {
    value = var.project_id
}

output "region" {
    value = local.region
}

output "zone" {
    value = local.zone
}

output "instance_name" {
  value = google_compute_instance.geth.name
}