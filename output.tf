output instance_hostname {
  value = "${google_compute_instance.prometheus.name}.c.${google_compute_instance.prometheus.project}.internal"
}

output instance_name {
  value = google_compute_instance.prometheus.name
}

output instance_address {
  value = google_compute_instance.prometheus.network_interface[0].access_config[0].nat_ip
}

output service_account_email {
  value = google_service_account.prometheus.email
}

output service_account_name {
  value = google_service_account.prometheus.name
}
