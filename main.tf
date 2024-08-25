provider "google" {
    credentials = file("~/Documents/Hogwarts/techeerism-94823f84d155.json")
    project = "techeerism"
    region  = "us-central1"  # Replace with your preferred region
    zone    = "us-central1-c"  # Replace with your preferred zone
}

variable "ssh_key" {
    type        = string
    description = "SSH public key"
}

resource "google_compute_network" "vpc_network" {
    name                    = "hogwarts-vpc-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
    name          = "hogwarts-subnet"
    ip_cidr_range = "10.0.0.0/16"
    network       = google_compute_network.vpc_network.id
    region        = "us-central1"
}

resource "google_compute_address" "static_ip1" {
    name   = "hogwarts-main-static-ip"
    region = "us-central1"
}

resource "google_compute_address" "static_ip2" {
    name   = "hogwarts-jenkins-static-ip"
    region = "us-central1"
}

resource "google_compute_address" "static_ip3" {
    name   = "hogwarts-monitoring-static-ip"
    region = "us-central1"
}

resource "google_compute_firewall" "main-ssh-icmp" {
    name    = "main-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["22", "80", "443", "9000", "2377", "7946", "9090", "3000", "8090"]  # SSH port
    }

    allow {
        protocol = "udp"
        ports = ["4789","7946"]
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["main-firewall"]
}

resource "google_compute_firewall" "jenkins-ssh-icmp" {
    name    = "jenkins-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["22", "80", "443", "8000", "7946"]  # SSH port
    }

    allow {
        protocol = "udp"
        ports = ["4789","7946"]
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["jenkins-firewall"]
}

resource "google_compute_firewall" "monitoring-ssh-icmp" {
    name    = "monitoring-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["22", "80", "443", "7946"]  # SSH port
    }

    allow {
        protocol = "udp"
        ports = ["4789", "7946"]
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["monitoring-firewall"]
}

# 백엔드 메인 서버 
resource "google_compute_instance" "vm_instance1" {
    name         = "hogwarts-main-instance"
    machine_type = "e2-medium"  # 2 vCPUs, 4GB memory
    zone         = "us-central1-c"
    allow_stopping_for_update = true

    boot_disk {
    initialize_params {
        image  = "ubuntu-os-cloud/ubuntu-2004-lts"
        size   = 25  # 25 GB disk size
        type   = "pd-balanced"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        access_config {
            nat_ip = google_compute_address.static_ip1.address
        }
    }

    tags = ["http-server", "https-server", "main-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}

# 젠킨스 서버
resource "google_compute_instance" "vm_instance2" {
    name         = "hogwarts-jenkins-instance"
    machine_type = "e2-small"  # 2 vCPUs, 2GB memory
    zone         = "us-central1-c"

    boot_disk {
    initialize_params {
        image  = "ubuntu-os-cloud/ubuntu-2004-lts"
        size   = 25  # 25 GB disk size
        type   = "pd-balanced"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        access_config {
            nat_ip = google_compute_address.static_ip2.address
        }
    }

    tags = ["http-server", "https-server", "jenkins-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}

# 모니터링 서버
resource "google_compute_instance" "vm_instance3" {
    name         = "hogwarts-monitoring-instance"
    machine_type = "e2-small"  # 2 vCPUs, 2GB memory
    zone         = "us-central1-c"

    boot_disk {
    initialize_params {
        image  = "ubuntu-os-cloud/ubuntu-2004-lts"
        size   = 25  # 25 GB disk size
        type   = "pd-balanced"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        access_config {
            nat_ip = google_compute_address.static_ip3.address
        }
    }

    tags = ["http-server", "https-server", "monitoring-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}