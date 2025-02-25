source "googlecompute" "ubuntu" {
  project_id            = var.gcp_project_id
  region                = var.gcp_region
  zone                  = var.gcp_zone
  network               = var.gcp_network
  subnetwork            = var.gcp_subnetwork
  machine_type          = var.gcp_machine_type
  source_image_family   = var.gcp_source_image_family
  image_name            = "${var.gcp_image_name}-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  image_family          = var.gcp_source_image_family
  ssh_username          = var.ssh_username
  service_account_email = "${var.gcp_service_account_email}@${var.gcp_project_id}.iam.gserviceaccount.com"
}

build {
  sources = ["source.googlecompute.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo ufw allow 'Nginx Full'",
      "sudo apt install -y tomcat9 tomcat9-admin",
      "sudo apt install -y openjdk-17-jdk",
      "sudo apt install -y mysql-server",
      "sudo systemctl enable mysql",
      "sudo systemctl start mysql.service",
      "sudo ufw allow 8080/tcp",
      "sudo ufw allow 3306/tcp",
      "sudo ufw reload",
      "echo 'Build Complete'"
    ]
  }
}

