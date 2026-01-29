
resource "cloudflare_zero_trust_access_application" "my_zero_trust_app" {
  domain                      = "${var.app_subdomain_name}.${var.app_domain_name}"
  name                        = "${var.app_name} - TF App"
  type                        = "self_hosted"
  zone_id                     = var.app_zone_id
  allow_authenticate_via_warp = var.app_allow_warp_login
  allow_iframe                = var.app_allow_iframe
  allowed_idps                = var.app_identity_providers
  app_launcher_visible        = true
  auto_redirect_to_identity   = true
  destinations                = var.destinations
  enable_binding_cookie       = false
  http_only_cookie_attribute  = true
  options_preflight_bypass    = false
  path_cookie_attribute       = true
  policies                    = var.app_policies
  same_site_cookie_attribute  = "none"
  session_duration            = "24h"
  skip_interstitial           = true
  tags                        = var.app_tags
}

resource "cloudflare_dns_record" "example_dns_record" {
  count   = var.tunnel_routing.create_cname ? 1 : 0
  zone_id = var.app_zone_id
  name    = "${var.app_subdomain_name}.${var.app_domain_name}"
  ttl     = 1
  type    = "CNAME"
  comment = "TF Managed CNAME for app ${var.app_name}"
  content = "${var.tunnel_routing.tunnel_id}.cfargotunnel.com"
  proxied = true
  settings = {
    flatten_cname = false
  }
}
