
provider "google" {
  credentials = file(var.deployKeyName)
  project     = var.project
  region      = var.region
  zone        = var.zone
}




resource "google_compute_instance" "vm_instance" {

  ## for a setup having multiple instances of the same type, you can do
  ## the following, there would be 2 instances of the same configuration
  ## provisioned
  count        = var.machineCount
  name         = "${var.instance-name}-${count.index}"

  machine_type = var.machineType

  tags         = ["locust"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
}
resource "google_compute_firewall" "locust_internal" {
  name    = "allow-locust-distributed"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5557", "5558"]
  }

  # This allows communication between VMs in the default VPC
  source_ranges = ["10.0.0.0/8"] 
  
  # This ensures the rule applies to instances with this tag
  target_tags = ["locust"]
}

output "loadgen_ips" {
  value = google_compute_instance.vm_instance[*].network_interface.0.access_config.0.nat_ip
  description = "The public IP addresses of the deployed instances"
}

