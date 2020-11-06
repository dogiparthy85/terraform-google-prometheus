data google_project current {

}

resource random_id network_tag {
  byte_length = 4
}

resource google_compute_firewall allow_http {
  name = "${var.name}-http"
  network = "default"
  source_ranges = ["0.0.0.0/0"]
  target_tags = [local.network_tag]

  allow {
    protocol = "TCP"
    ports = ["9090"]
  }
}

resource google_service_account prometheus {
  account_id = var.name
}

resource google_project_iam_member monitoring_metricWriter {
  member = "serviceAccount:${google_service_account.prometheus.email}"
  role = "roles/monitoring.metricWriter"
}

resource google_compute_disk data {
  count = var.data_disk_enabled ? 1 : 0
  name = "${var.name}-data"
  size = var.data_disk_size
  type = var.data_disk_type
  zone = var.zone
}

resource google_compute_instance prometheus {
  name = var.name
  machine_type = var.machine_type
  labels = var.labels
  tags = concat([local.network_tag], var.tags)
  zone = var.zone
  allow_stopping_for_update = true

  metadata = {
    user-data = "#cloud-config\n${yamlencode(local.cloud_init_config)}"
  }

  service_account {
    email = google_service_account.prometheus.email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size = var.disk_size
      type = var.disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.data
    content {
      source = attached_disk.value.self_link
      device_name = attached_disk.value.name
    }
  }

  network_interface {
    network = "default"

    dynamic "access_config" {
      for_each = var.address != null ? [var.address] : [""]
      content {
        nat_ip = access_config.value
      }
    }
  }
}
