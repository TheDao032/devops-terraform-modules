variable "traefik_dashboard_ingroute_name" {
  description = "Traefik dashboard"
  type        = string
  default     = "traefik-dashboard"
}

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
variable "traefik_conf" {
  description = "alloy Conf Data"
  type        = map(any)
  default     = {}
}
