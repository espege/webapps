resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.personal_domain.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "security_header" {
  zone_id    = cloudflare_zone.personal_domain.id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      max_age            = 31536000
      include_subdomains = true
      preload            = false
    }
  }
}
