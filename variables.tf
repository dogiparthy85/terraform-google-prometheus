variable machine_type {
  type = string
  default = "f1-micro"
}

variable disk_size {
  type = number
  default = 20
}

variable disk_type {
  type = string
  default = "pd-standard"
}

variable address {
  type = string
  default = null
}

variable use_ephemeral_address {
  type = bool
  default = true
}

variable name {
  type = string
  default = null
}

variable name_prefix {
  type = string
  default = "prometheus-"
}

variable endpoints {
  type = list(object({ url = string, interval = number }))
  default = []
}

locals {
  cloud_init_config = ""
}
