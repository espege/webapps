# CloudFlare application using private tunnel

variable "app_zone_id" {
  type        = string
  description = "CloudFlare zone ID where app will exist"
}

variable "app_domain_name" {
  type        = string
  description = "DNS Domain"
}

variable "app_policies" {
  type = list(object({
    id         = string
    precedence = number
  }))
  description = "List of policies to determine app access"
}

variable "app_subdomain_name" {
  type        = string
  description = "DNS Subdomain"
}

variable "app_allow_warp_login" {
  type        = bool
  description = "Whether or not to allow Warp login"
  default     = false
}

variable "app_allow_iframe" {
  type        = bool
  description = "Whether or not to allow iFrame"
  default     = false
}

variable "app_identity_providers" {
  type        = list(string)
  description = "List of identity providers allowed to authenticate"
}

variable "app_name" {
  type        = string
  description = "Cloudflare Application Name"
}

variable "app_tags" {
  type        = list(string)
  description = "List of tags to add to application"
}

variable "destinations" {
  type        = list(map(string))
  description = "List of destinations"
}

variable "tunnel_routing" {
  type = object({
    create_cname = optional(bool, true)
    tunnel_id    = string
  })
}
