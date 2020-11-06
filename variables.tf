variable name {
  type = string
  description = "The name to give this instance."
}

variable machine_type {
  type = string
  default = "f1-micro"
  description = "The instance type to create this Prometheus instance as."
}

variable disk_size {
  type = number
  default = 10
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

variable data_disk_enabled {
  type = bool
  default = false
}

variable data_disk_size {
  type = number
  default = 50
}

variable data_disk_type {
  type = string
  default = "pd-balanced"
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
