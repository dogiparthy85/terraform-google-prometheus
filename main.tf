resource random_id name_suffix {
  byte_length = 2
  keepers = {
    machine_type = sha1(var.machine_type)
    cloud_init_config = sha1(yamlencode(local.cloud_init_config))
    disk_size = sha1(var.disk_size)
    disk_type = sha1(var.disk_type)
    zone = sha1(var.zone)
  }
}

resource google_service_account prometheus {
  account_id = "prometheus-${random_id.name_suffix.hex}"
}

resource google_project_iam_member monitoring_metricWriter {
  member = "serviceAccount:${google_service_account.prometheus.email}"
  role = "roles/monitoring.metricWriter"
}

resource google_compute_instance prometheus {
  name = var.name != null ? var.name : "${var.name_prefix}${random_id.name_suffix.hex}"
  machine_type = var.machine_type
  labels = var.labels
  tags = var.tags
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

  network_interface {
    network = "default"

    dynamic "access_config" {
      for_each = var.address != null ? [var.address] : [""]
      content {
        nat_ip = access_config.value
      }
    }
  }

  depends_on = [random_id.name_suffix]
}
