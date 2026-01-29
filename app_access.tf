# Required for reusable access groups with email lists
resource "cloudflare_zero_trust_list" "email_list" {
  for_each    = local.email_lists_data
  account_id  = cloudflare_account.my_account.id
  name        = each.key
  type        = "EMAIL"
  description = "List of emails for reusable access group ${each.key}, terraform-managed"
  items = [for email_list in each.value : {
    description = "Terraform managed email entry for ${each.key}"
    value       = email_list
  }]
}

# Create the access groups from local
resource "cloudflare_zero_trust_access_group" "my_access_groups" {
  for_each   = local.access_groups_data
  depends_on = [cloudflare_zero_trust_list.email_list]
  name       = "${lookup(each.value, "name", each.key)} - TF Access Group"
  account_id = cloudflare_account.my_account.id
  zone_id    = cloudflare_zone.personal_domain.id
  is_default = lookup(each.value, "is_default", false)
  include    = each.value.include
  require    = try(each.value.require, [])
  exclude    = try(each.value.exclude, [])
}

# Create the access policies from local
resource "cloudflare_zero_trust_access_policy" "access_policy" {
  for_each   = local.access_policy_data
  depends_on = [cloudflare_zero_trust_access_group.my_access_groups]

  account_id        = cloudflare_account.my_account.id
  name              = "${lookup(each.value, "policy_name", each.key)} - TF Access Policy"
  decision          = lookup(each.value, "decision", "allow")
  session_duration  = each.value.session_duration
  approval_required = lookup(each.value, "approval_required", false)
  include           = each.value.include
  require           = try(each.value.require, [])
  exclude           = try(each.value.exclude, [])
}
