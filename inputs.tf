variable "public" {
  type = bool
  default = false
}

variable "command" {
  type = string
  default = null
}

variable "cpu" {
  type = number
  default = 128
}

variable "mem" {
  type = number
  default = 512
}

variable "certificate" {
  type = bool
  default = true
}

variable "certificate_alt_names" {
  type = string
  default = null
}

variable "autoscaling" {
  type = bool
  default = false
}

variable "autoscaling_min" {
  type = number
  default = 3
}

variable "autoscaling_max" {
  type = number
  default = 3
}

variable "target_port" {
  type = number
  default = 80
}

variable "target_protocol" {
  type = string
  default = "http"
}

variable "listener_port" {
  type = number
  default = 443
}

variable "listener_protocol" {
  type = string
  default = "https"
}

variable "health_check_path" {
  type = string
  default = "/"
}

variable "health_check_timeout" {
  type = number
  default = 60
}

variable "health_check_grace_period" {
  type = number
  default = 120
}
