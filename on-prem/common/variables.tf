# variable "coredns_chart_info" {
#   description = "alloy Conf Data"
#   type        = map(any)
#   default     = {}
# }
#
# variable "coredns_conf" {
#   description = "alloy Conf Data"
#   type        = map(any)
#   default     = {}
# }
#

variable "environment" {
  type = string
}

variable "traefik_conf" {
  description = "Traefik Conf Data"
  type        = map(any)
  default     = {}
}

variable "coredns_conf" {
  description = "CoreDNS Conf Data"
  type        = map(any)
  default     = {}
}

variable "dashboard_ingroute_name" {
  description = "Traefik dashboard"
  type        = string
  default     = "traefik-dashboard"
}
