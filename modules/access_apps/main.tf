terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.1.0"
    }
  }
}

resource "cloudflare_zero_trust_access_application" "access_app" {
  domain                      = var.app_domain_name
  type                        = var.app_type
  zone_id                     = var.zone_id
  allow_authenticate_via_warp = false
  allowed_idps                = var.identity_providers
  app_launcher_visible        = true
  auto_redirect_to_identity   = true
  destinations                = var.uri_list
  enable_binding_cookie       = false
  http_only_cookie_attribute  = true
  name                        = var.app_name
  options_preflight_bypass    = false
  path_cookie_attribute       = true
  policies                    = var.policies
  same_site_cookie_attribute  = "none"
  self_hosted_domains         = var.self_hosted_domains
  session_duration            = var.session_duration
  skip_interstitial           = true
  tags                        = var.tags
}
