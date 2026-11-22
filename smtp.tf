
resource "cloudflare_dns_record" "smtp_verified_sender_records" {
  for_each = var.smtp_verified_sender_records
  zone_id  = cloudflare_zone.personal_domain.id
  name     = "${each.key}.${cloudflare_zone.personal_domain.name}"
  ttl      = 1
  type     = "CNAME"
  comment  = "Verify Sender DNS records"
  content  = each.value.content
  proxied  = false
  settings = {
    flatten_cname = false
  }
}
