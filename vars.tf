locals {
  apps_yaml = yamldecode(file("${path.module}/apps.yaml"))
  all_tags = flatten([
    for app in local.apps_yaml : app.tags
  ])
  policies = {
    global_pol_homeusers = cloudflare_zero_trust_access_policy.Global_Pol_Homeowners
  }
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "Your API token"
  type        = string
}

variable "TUNNEL_ID" {
  description = "Your tunnel ID"
  type        = string
}

variable "DOMAIN_ID" {
  description = "Your domain ID"
  type        = string
}

variable "DOMAIN_NAME" {
  description = "Your domain name"
  type        = string
}

# Access Groups Vars
variable "EMAIL_ADDRESSES_MAIN" {
  description = "email addresses"
  type        = list(string)
}

# Auth providers
variable "GOOGLE_CLIENT_ID" {
  description = "Google Client ID"
  type        = string
}

variable "HOME_USERS_ACCESS_GROUP" {
  description = "Home users"
  type = object({
    name = string
    include = list(object({
      email = object({
        email = string
      })
    })),
    require = list(object({
      geo = object({
        country_code = string
      })
    }))
  })
}

variable "CLOUDFLARE_ACCOUNT_NAME" {
  description = "Your Cloudflare account name"
  type        = string
}
