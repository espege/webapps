output "overview" {
  value = {
    tunnel_files_count             = length(local.tunnel_file)
    reusable_access_groups_count   = length(local.access_groups_data)
    reusable_access_policies_count = length(local.access_policy_data)
    unique_email_list_count        = length(var.EMAIL_LISTS)
    email_lists_keys               = keys(var.EMAIL_LISTS)
    access_policy_data_keys        = keys(local.access_policy_data)
  }
}
