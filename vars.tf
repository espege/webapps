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

variable "REVERSE_PROXY_INTERNAL_IP_ADDRESS" {
  description = "Private IP address for reverse proxy. Used to create cloudflare_zero_trust_tunnel_cloudflared_config"
  type        = string
}

variable "EMAIL_LISTS" {
  description = "Map of email lists to create. Reused in access groups. Key is the name of the email list, value is a list of emails to add to the list."
  type        = map(list(string))
  default     = {
    "engineering" = []
  }
}

locals {
  tunnel_file         = [for f in fileset(path.module, "${path.module}/tunnels/*.yaml") : f if !endswith(f, "sample.yaml")]
  tunnel_data         = { for tun in local.tunnel_file : element(split("/", trimsuffix(tun, ".yaml")), -1) => yamldecode(file(tun)) }
  access_groups_files = [for f in fileset(path.module, "${path.module}/reusable_access_groups/*.tftpl") : f if !endswith(f, "sample.tftpl")]

  access_groups_data = {
    for access_file in local.access_groups_files : basename(trimsuffix(access_file, ".tftpl")) => yamldecode(templatefile(access_file, {
      email_list = cloudflare_zero_trust_list.email_list[trimsuffix(basename(access_file), ".tftpl")].id
    }))
  }


  # Access Policies
  access_policy_files = [for f in fileset(path.module, "${path.module}/reusable_access_policies/*.tftpl") : f if !endswith(f, "sample.tftpl")]
  access_policy_data = {
    for access_file in local.access_policy_files : basename(trimsuffix(access_file, ".tftpl")) => yamldecode(templatefile(access_file, {
      access_group_name = cloudflare_zero_trust_access_group.my_access_groups[trimsuffix(basename(access_file), ".tftpl")].id
      google_auth       = cloudflare_zero_trust_access_identity_provider.google.id
    }))
  }

  # Applications
  applications = [for f in fileset(path.module, "${path.module}/apps/*.tftpl") : f if !endswith(f, "sample.tftpl")]
  applications_data = {
    for app in local.applications : basename(trimsuffix(app, ".tftpl")) => yamldecode(templatefile(app, {
      personal_domain = cloudflare_zone.personal_domain.name
      google_auth     = cloudflare_zero_trust_access_identity_provider.google.id
      file_name       = basename(trimsuffix(app, ".tftpl"))
      proxy_ip        = var.REVERSE_PROXY_INTERNAL_IP_ADDRESS
      home_lab_tunnel = cloudflare_zero_trust_tunnel_cloudflared.tunnels["home_lab_tunnel"].id
    }))
  }
  tunnel_ingress = [
    for cnf in values(local.applications_data) : {
      service        = "${try(cnf.ingress.protocol, "https")}://${try(cnf.ingress.host, "localhost")}:${try(cnf.ingress.port, "443")}"
      hostname       = "${cnf.app_subdomain_name}.${cnf.app_domain_name}"
      origin_request = try(cnf.ingress.origin_request, null)
    }
  ]
  all_tags = concat([for k, v in local.applications_data : v.app_tags]...)

}
