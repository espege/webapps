# export TF_VAR_CLOUDFLARE_API_TOKEN=xyz

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.1.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

resource "cloudflare_account" "personal" {
  name = var.CLOUDFLARE_ACCOUNT_NAME
  type = "standard"
}

resource "cloudflare_zone" "main_zone" {
  account = {
    id = var.DOMAIN_ID
  }
  name = var.DOMAIN_NAME
  type = "full"
}

# Access Apps

resource "cloudflare_zero_trust_access_identity_provider" "google" {
  account_id = cloudflare_account.personal.id
  config = {
    client_id    = var.GOOGLE_CLIENT_ID
    pkce_enabled = true
  }
  scim_config = {
    enabled                  = false
    identity_update_behavior = "no_action"
    seat_deprovision         = false
    user_deprovision         = false
  }
  name = "Google"
  type = "google"
}

module "zero_trust_app_tags" {
  source     = "./modules/tags"
  for_each   = toset(local.all_tags)
  TAG_NAME   = each.value
  ACCOUNT_ID = cloudflare_account.personal.id
}

module "google_auth_acess_app" {
  source             = "./modules/access_apps"
  for_each           = { for k, v in local.apps_yaml : k => v }
  app_domain_name    = each.value.domain
  app_type           = each.value.type
  app_name           = each.value.name
  zone_id            = cloudflare_zone.main_zone.id
  identity_providers = [cloudflare_zero_trust_access_identity_provider.google.id]
  uri_list           = each.value.destinations
  policies = [{
    id       = local.policies.global_pol_homeusers.id
    decision = "allow"
  }]
  self_hosted_domains = each.value.self_hosted_domains
  session_duration    = each.value.session_duration
  tags                = each.value.tags
}

# Users and Groups

resource "cloudflare_zero_trust_access_group" "home_users" {
  include    = var.HOME_USERS_ACCESS_GROUP.include
  require    = var.HOME_USERS_ACCESS_GROUP.require
  name       = var.HOME_USERS_ACCESS_GROUP.name
  zone_id    = cloudflare_zone.main_zone.id
  is_default = false
}


# Global (reusable) policy

resource "cloudflare_zero_trust_access_policy" "Global_Pol_Homeowners" {
  account_id = cloudflare_account.personal.id
  name       = "Allow HomeOwners"
  decision   = "allow"
  include = [{
    group = {
      id = cloudflare_zero_trust_access_group.home_users.id
    }
  }]
  require = [{
    group = {
      id = cloudflare_zero_trust_access_group.home_users.id
    }
  }]
  session_duration = "72h"
}
