variable "app_domain_name" {
  description = "The domain name to use for the Access App"
  type        = string
}

variable "app_type" {
  description = "The type of the Access App"
  type        = string
  default     = "self_hosted"
}

variable "app_name" {
  description = "The name of the Access App"
  type        = string
}

variable "zone_id" {
  description = "The zone ID to use for the Access App"
  type        = string
}

variable "identity_providers" {
  description = "The identity providers to use for the Access App"
  type        = list(string)
}

variable "uri_list" {
  description = "The list of URIs to use for the Access App"
  type        = list(map(string))
  validation {
    condition = alltrue([
      for uri in var.uri_list : contains(keys(uri), "type") && contains(keys(uri), "uri")
    ])
    error_message = "Each map in uri_list must contain keys 'type' and 'uri'."
  }
}

variable "policies" {
  description = "The policies to use for the Access App"
  type = list(object({
    id       = string
    decision = string
    })
  )
}

variable "self_hosted_domains" {
  description = "The self hosted domains to use for the Access App"
  type        = list(string)
}

variable "session_duration" {
  description = "The session duration for the Access App"
  type        = string
  default     = "24h"
}

variable "tags" {
  description = "The tags to use for the Access App"
  type        = list(string)
}
