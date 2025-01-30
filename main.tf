provider "google" {
    credentials = file("~/Documents/Hogwarts/techeerism-94823f84d155.json")
    project = "techeerism"
    region  = "us-central1"  
    zone    = "us-central1-c" 
}

provider "google-beta" {
  credentials = file("~/Documents/Hogwarts/techeerism-94823f84d155.json")
  project     = "techeerism"
  region      = "us-central1"
  zone        = "us-central1-c"
}

variable "project_id" {
  type        = string
  description = "Google Cloud 프로젝트 ID"
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
    name   = "hogwarts-monitoring-static-ip"
    region = "us-central1"
}

resource "google_compute_address" "static_ip3" {
    name   = "hogwarts-crawling-static-ip"
    region = "us-central1"
}

resource "google_compute_address" "static_ip4" {
    name   = "hogwarts-parsing-static-ip"
    region = "us-central1"
}


resource "google_compute_firewall" "main-ssh-icmp" {
    name    = "main-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["443"]  # SSH port
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["main-firewall"]
}

resource "google_compute_firewall" "monitoring-ssh-icmp" {
    name    = "monitoring-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["443"]  # SSH port
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["monitoring-firewall"]
}

resource "google_compute_firewall" "crawling-ssh-icmp" {
    name    = "crawling-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["443"]  # SSH port
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["crawling-firewall"]
}

resource "google_compute_firewall" "parsing-ssh-icmp" {
    name    = "parsing-ssh-icmp"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["443"]  # SSH port
    }

    allow {
        protocol = "icmp"
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["parsing-firewall"]
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
        startup-script = <<-EOF
            #!/bin/bash
            # Cloud SQL Proxy 설치
            wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
            chmod +x cloud_sql_proxy
            
            # Cloud SQL Proxy 실행
            ./cloud_sql_proxy -instances=${var.project_id}:us-central1:hogwarts-postgres-instance=tcp:5432 &

            # Docker 및 NestJS 설정 실행
            bash ~/Documents/Hogwarts/infra/docker.sh
        EOF
    }
}

# 모니터링 서버
resource "google_compute_instance" "vm_instance2" {
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
            nat_ip = google_compute_address.static_ip2.address
        }
    }

    tags = ["http-server", "https-server", "monitoring-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}

# 크롤링 서버
resource "google_compute_instance" "vm_instance3" {
    name         = "hogwarts-crawling-instance"
    machine_type = "e2-micro"  # 코어 1, 1GB memory
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

    tags = ["http-server", "https-server", "crawling-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}

# 파싱 서버
resource "google_compute_instance" "vm_instance4" {
    name         = "hogwarts-parsing-instance"
    machine_type = "e2-micro"  # 코어 1, 1GB memory
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
            nat_ip = google_compute_address.static_ip4.address
        }
    }

    tags = ["http-server", "https-server", "parsing-firewall"]

    metadata = {
        ssh-keys = "ubuntu:${var.ssh_key}"
        startup-script = file("~/Documents/Hogwarts/infra/docker.sh")
    }
}



# PostgreSQL 설정

variable "db_name" {}
variable "db_charset" {}
variable "db_user_name" {}
variable "db_user_password" {}

variable "db_machine_type" {
  description = "DB 머신 타입"
  type        = string
  default     = "db-custom-1-3840"  # 1 CPU, 3840MB 메모리
}

# VPC Peering 설정
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id 
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# PostgreSQL Cloud SQL 설정
resource "google_sql_database_instance" "hogwarts_postgres" {
  name                = var.db_name
  project             = var.project_id
  region              = "us-central1"
  database_version    = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier               = var.db_machine_type
    availability_type  = "ZONAL"
    disk_size          = 20

    maintenance_window {
      day           = 7
      hour          = 12
      update_track  = "stable"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc_network.id
      
      authorized_networks {
        name  = "allowed-network"
        value = "0.0.0.0/0"  # 외부 접근 허용 범위 설정 (특정 IP로 제한 가능)
      }
    }

    database_flags {
      name  = "autovacuum"
      value = "off"
    }

    backup_configuration {
      enabled    = true
      start_time = "20:55"
    }
  }
}

// 데이터베이스 사용자 설정
resource "google_sql_user" "db_user" {
  name     = var.db_user_name
  password = var.db_user_password
  instance = google_sql_database_instance.hogwarts_postgres.name

  depends_on = [google_sql_database_instance.hogwarts_postgres]
}