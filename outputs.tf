output "overview" {
  value = {
    tunnel_count                   = length(var.cloudflare_tunnels)
    reusable_access_groups_count   = length(var.access_groups)
    reusable_access_policies_count = length(var.access_policies)
    unique_email_list_count        = length(var.EMAIL_LISTS)
    email_lists_keys               = keys(var.EMAIL_LISTS)
    access_policy_data_keys        = keys(var.access_policies)
    deployed_app_keys              = keys(local.applications)
  }
}
