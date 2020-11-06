variable machine_type {
  type = string
  default = "f1-micro"
  description = "The instance type to create this Prometheus instance as."
}

variable disk_size {
  type = number
  default = 20
  description = "Disk size (in GB) to assign to the instance."
}

variable disk_type {
  type = string
  default = "pd-standard"
  description = "Disk type to use (one of pd-ssd or pd-standard)."
}

variable zone {
  type = string
  description = "Zone in which to place the instance."
}

variable address {
  type = string
  default = null
  description = "The external IP address to assign to this instance."
}

variable name {
  type = string
  default = null
  description = "The name to give this instance."
}

variable name_prefix {
  type = string
  default = "prometheus-"
  description = "The name prefix to give this instance (suffix will be generated). Ignored if `name` is provided."
}

variable default_scrape_interval {
  type = number
  default = 30
}

variable default_scrape_timeout {
  type = number
  default = 25
}

variable image {
  type = string
  default = "gcr.io/stackdriver-prometheus/stackdriver-prometheus:release-0.4.1"
}

variable endpoints {
  type = list(object({
    url = string,
    interval = number,
    timeout = number,
    auth_basic = tuple([string, string]),
    auth_token = string
  }))
  default = []
  description = "A list of endpoints to scrape for metrics."
}

variable labels {
  type = map(string)
  default = {}
}

variable log_level {
  type = string
  default = "info"
}

variable tags {
  type = list(string)
  default = []
}

variable write_to_stackdriver {
  type = bool
  default = false
}

locals {
  cloud_init_config = {
    write_files: concat(
      [
        {
          permissions = "0755"
          path: "/home/run_prometheus.sh"
          content: templatefile("${path.module}/run_prometheus.sh", { project = data.google_project.current.project_id, log_level = var.log_level })
        },
        {
          permissions = "0644"
          path = "/etc/prometheus.yml"
          content = yamlencode(local.prom_config)
        }
      ], var.write_to_stackdriver ? [
        {
          permissions = "0755"
          path = "/home/run_sidecar.sh"
          content = templatefile("${path.module}/run_sidecar.sh", { project = data.google_project.current.project_id, log_level = var.log_level })
        }
      ] : []
    )
    runcmd: concat(
      [
        "docker network create prometheus || true &> /dev/null",
        "sh /home/run_prometheus.sh",
      ],
      var.write_to_stackdriver ? ["sleep 5", "sh /home/run_sidecar.sh"] : []
    )
  }

  parsed_endpoints = [
    for index, endpoint in var.endpoints:
      merge(
        endpoint,
        regex("(?:(?P<scheme>[^:/?#]+):)?(?://(?P<host>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?", endpoint.url)
      )
  ]

  instance_name = var.name != null ? var.name : "${var.name_prefix}${random_id.name_suffix.hex}"

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
              __meta_gce_instance_id = local.instance_name
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
