resource "cloudflare_account" "my_account" {
  name = var.CLOUDFLARE_ACCOUNT_NAME
  type = "standard"
}

resource "cloudflare_zone" "personal_domain" {
  account = {
    id = cloudflare_account.my_account.id
  }
  name = var.CLOUDFLARE_GENERIC_DOMAIN_NAME
  type = "full"
}

resource "cloudflare_zero_trust_access_identity_provider" "google" {
  config = {
    client_id    = var.GOOGLE_CLIENT_ID
    pkce_enabled = true
  }
  name       = "Google"
  type       = "google"
  account_id = cloudflare_account.my_account.id
}

resource "cloudflare_zero_trust_access_tag" "tags" {
  for_each   = toset(local.all_tags)
  account_id = cloudflare_account.my_account.id
  name       = each.value
}

module "my_apps" {
  for_each               = local.applications
  source                 = "./modules/self_hosted_apps"
  depends_on             = [cloudflare_zero_trust_access_tag.tags]
  destinations           = each.value.destinations
  app_domain_name        = each.value.domain
  app_subdomain_name     = each.value.subdomain
  app_name               = each.value.name
  app_tags               = each.value.app_tags
  app_zone_id            = cloudflare_zone.personal_domain.id
  app_identity_providers = each.value.identity_providers
  app_policies = [for k, v in each.value.policies : {
    id         = (cloudflare_zero_trust_access_policy.access_policy[v.policy_key]).id
    precedence = v.precedence
  }]
  tunnel_routing = {
    tunnel_id = each.value.tunnel_id
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnels" {
  for_each   = var.cloudflare_tunnels
  name       = each.value.name
  account_id = each.value.account_id == "default" ? cloudflare_account.my_account.id : each.value.account_id
  config_src = "cloudflare"
  depends_on = [cloudflare_account.my_account]
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "home_lab_config" {
  account_id = cloudflare_account.my_account.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels["home_lab_tunnel"].id
  source     = "cloudflare"
  config = {
    ingress = concat(local.tunnel_ingress,
      [{ service = "http_status:404" }] # Catch-all
    )
  }
}
