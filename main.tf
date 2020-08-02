resource random_id prometheus_name_prefix {
  byte_length = 2
  keepers = {
    machine_type = var.machine_type
    cloud_init_config = local.cloud_init_config
    disk_size = var.disk_size
    disk_type = var.disk_type
  }
}

resource google_compute_instance prometheus {
  name = var.name != null ? var.name : "${var.name_prefix}${random_id.prometheus_name_prefix.hex}"
  machine_type = random_id.prometheus_name_prefix.keepers.machine_type

  metadata = {
    user-data = random_id.prometheus_name_prefix.keepers.cloud_init_config
  }

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size = random_id.prometheus_name_prefix.keepers.disk_size
      type = random_id.prometheus_name_prefix.keepers.disk_type
    }
  }

  network_interface {
    dynamic "access_config" {
      for_each = var.address != null ? [var.address] : [""]
      content {
        nat_ip = access_config.value
      }
    }
  }
}
