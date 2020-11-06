locals {
  cloud_init_config = {
    write_files: concat(
      [
        {
          permissions = "0755"
          path: "/var/scripts/run_prometheus.sh"
          content: templatefile("${path.module}/startup/run_prometheus.sh", { project = data.google_project.current.project_id, log_level = var.log_level })
        },
        {
          permissions = "0644"
          path = "/etc/prometheus.yml"
          content = yamlencode(local.prom_config)
        }
      ],
      var.write_to_stackdriver ? [{
        permissions = "0755"
        path = "/var/scripts/run_sidecar.sh"
        content = templatefile("${path.module}/startup/run_sidecar.sh", { project = data.google_project.current.project_id, log_level = var.log_level })
      }] : [],
      var.data_disk_enabled ? [
        {
          permissions = "0755"
          path = "/var/scripts/format_disk.sh"
          content = templatefile("${path.module}/startup/format_disk.sh", { name = var.name })
        },
        {
          permissions = "0755"
          path = "/var/scripts/create_volume.sh"
          content = templatefile("${path.module}/startup/create_volume.sh", { name = var.name })
        }
      ] : []
    )
    runcmd = concat(
      ["docker network create prometheus || true &> /dev/null"],
      var.data_disk_enabled ? ["sh /var/scripts/format_disk.sh", "sh /var/scripts/create_volume.sh"] : [],
      ["sh /var/scripts/run_prometheus.sh"],
      var.write_to_stackdriver ? ["sleep 5", "sh /var/scripts/run_sidecar.sh"] : []
    )
  }

  parsed_endpoints = [
    for index, endpoint in var.endpoints:
      merge(
        endpoint,
        regex("(?:(?P<scheme>[^:/?#]+):)?(?://(?P<host>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?", endpoint.url)
      )
  ]

  network_tag = "${var.name}-${random_id.network_tag.hex}"

  prom_config = {
    global = {
      scrape_interval = "${var.default_scrape_interval}s"
      scrape_timeout = "${var.default_scrape_timeout}s"
    }
    scrape_configs = [
    for endpoint in local.parsed_endpoints: merge(
    {
      job_name = "scrape-target-${substr(sha256(endpoint.url), 0, 8)}"
      metrics_path = endpoint.path
      scheme = endpoint.scheme
      static_configs = [{
        targets = [endpoint.host]
        labels = var.write_to_stackdriver ? {
          __meta_gce_project = data.google_project.current.project_id
          __meta_gce_instance_id = var.name
          __meta_gce_zone = var.zone
        } : {}
      }]
      params = {
      for pair in (endpoint.query == null ? [] : split("&", endpoint.query)):
      length(split("=", pair)) > 0 ? split("=", pair)[0] : "" => [length(split("=", pair)) > 1 ? split("=", pair)[1] : ""]
      }
    },
    endpoint.interval != null ? { scrape_interval = "${endpoint.interval}s" } : {},
    endpoint.timeout != null ? { scrape_timeout = "${endpoint.timeout}s" } : {},
    endpoint.auth_basic != null ? { basic_auth = { username = endpoint.auth_basic[0], password = endpoint.auth_basic[1] } } : {},
    endpoint.auth_token != null ? { bearer_token = endpoint.auth_token } : {},
    )
    ]
  }
}
