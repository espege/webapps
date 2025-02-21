terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.1.0"
    }
  }
}

resource "cloudflare_zero_trust_access_tag" "tag" {
  account_id = var.ACCOUNT_ID
  name       = var.TAG_NAME
}
