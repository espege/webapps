variable "CLOUDFLARE_API_TOKEN" {
  type        = string
  description = "Cloudflare API Token"
  sensitive   = true
}

variable "CLOUDFLARE_ACCOUNT_NAME" {
  description = "Your Cloudflare account name"
  type        = string
}

variable "CLOUDFLARE_GENERIC_DOMAIN_NAME" {
  description = "Domain name"
  type        = string
}

variable "GOOGLE_CLIENT_ID" {
  description = "Google Client ID. Used to avoid recreating google ID provider"
  type        = string
}


variable "EMAIL_LISTS" {
  description = "Map of email lists to create. Reused in access groups. Key is the name of the email list, value is a list of emails to add to the list."
  type        = map(list(string))
  default = {
    "engineering" = []
  }
  validation {
    condition     = alltrue([for email_list in values(var.EMAIL_LISTS) : length(email_list) >= 1]) && alltrue([for email_list in values(var.EMAIL_LISTS) : alltrue([for email in email_list : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))])])
    error_message = "Each email list must contain at least one valid email address."
  }
}

variable "access_groups" {
  description = "Map of access groups to create. Key is the name of the access group, value is an object with the following properties: name (string), include (list of maps), require (list of maps), exclude (list of maps). The include, require, and exclude properties should be lists of maps that define the criteria for including, requiring, or excluding users from the access group. For example, an include map could look like { email_list = { id = \"email_list_id\" } } to include users from a specific email list."
  type = map(object({
    name       = string
    is_default = optional(bool, false)
    include    = optional(list(map(map(string))), [])
    require    = optional(list(map(map(string))), [{ "geo" : { "country_code" = "PLACEHOLDER" } }])
    exclude    = optional(list(map(map(string))), [])
  }))
  default = {
    default = {
      name       = "Default Access Group"
      is_default = true
      include    = []
      require    = []
      exclude    = []
    }
  }
}

variable "cloudflare_tunnels" {
  description = "Map of Cloudflare tunnels to create. Key is the name of the tunnel, value is an object with the following properties: name (string), config (map). The config property should be a map that defines the configuration for the tunnel, such as the tunnel's credentials file and any additional settings required for the tunnel."
  type = map(object({
    name       = string
    account_id = string
  }))
}

variable "access_policies" {
  description = "Map of access policies to create. Key is the name of the access policy, value is a list of email lists to include in the policy."
  type = map(object({
    policy_name       = string
    approval_required = optional(bool, false)
    decision          = optional(string, "allow")
    session_duration  = optional(string, "24h")
    include           = optional(list(map(map(string))), [])
    require           = optional(list(map(map(string))), [{ "geo" : { "country_code" = "PLACEHOLDER" } }])
    exclude           = optional(list(map(map(string))), [])
  }))
  default = {
    default = {
      policy_name      = "Default Policy"
      session_duration = "24h"
    }
  }
}

variable "cloudflare_applications" {
  description = "Map of Cloudflare applications to create. Key is the name of the application, value is an object with the following properties: name (string), domain (string), subdomain (string), ingress (map). The ingress property should be a map that defines the configuration for the application's ingress, such as the protocol, host, port, and any additional settings required for the application's ingress."
  type = map(object({
    name      = string
    domain    = string
    subdomain = string
    destinations = optional(list(object({
      type = string
      uri  = string
    })), null)
    tunnel_id          = optional(string, null)
    identity_providers = optional(list(string), [])
    policies = optional(list(object({
      policy_key = string
      precedence = number
    })), [])
    ingress = object({
      protocol       = optional(string, "https")
      host           = optional(string, "localhost")
      port           = optional(string, "443")
      origin_request = optional(map(string), { no_tls_verify = false })
    })
    app_tags = optional(list(string), null)
  }))
}

locals {
  access_policies_with_lookups = {
    for policy_name, policy_data in var.access_policies : policy_name => merge(
      policy_data,
      # Lookup for key "group" and "login_method" in include, require, exclude and convert id value to cloudflare_zero_trust_access_group.my_access_groups.id reference
      {
        for action in ["include", "require", "exclude"] : action => [
          for verb in policy_data[action] : merge(
            verb,
            contains(keys(verb), "group") ? {
              group = {
                id = try(
                  cloudflare_zero_trust_access_group.my_access_groups[verb.group.id].id,
                  null
                )
              }
            } : {},
            contains(keys(verb), "login_method") ? {
              login_method = {
                id = lookup(local.login_methods, verb.login_method.id, "UNKNOWN_LOGIN_METHOD ID: ${verb.login_method.id}")
              }
            } : {}
          )
        ]
      }
    )
  }

  access_group_with_email_lookups = {
    for group_name, group_data in var.access_groups : group_name => merge(
      group_data,
      # Lookup for key "email_list" in include, require, exclude and convert id value to cloudflare_zero_trust_list.email_list.id reference
      {
        for action in ["include", "require", "exclude"] : action => [
          for verb in group_data[action] : merge(
            verb,
            contains(keys(verb), "email_list") ? {
              email_list = {
                id = try(cloudflare_zero_trust_list.email_list[verb.email_list.id].id, null)
              }
            } : { for k, v in verb : k => v }
          )
        ]
      }
    )
  }

  applications = {
    for app_name, app_data in var.cloudflare_applications : app_name => merge(
      app_data,
      {
        tunnel_id          = try(cloudflare_zero_trust_tunnel_cloudflared.tunnels[app_data.tunnel_id].id, null)
        policies           = [for policy in app_data.policies : try(cloudflare_zero_trust_access_policy.access_policy[lower(title(policy))].id, policy)]
        identity_providers = [for idp in app_data.identity_providers : try(local.login_methods[lower(idp)], idp)]
      }
    )
  }

  tunnel_ingress = concat([
    for config in values(local.applications) : merge(
      {
        hostname       = "${config.subdomain}.${config.domain}"
        service        = "${try(config.ingress.protocol, "https")}://${try(config.ingress.host, "localhost")}:${try(config.ingress.port, "443")}"
        origin_request = config.ingress.origin_request
      }
    )
  ])

  all_tags = concat([for k, v in local.applications : v.app_tags]...)
  login_methods = {
    google_auth = cloudflare_zero_trust_access_identity_provider.google.id
  }
}
