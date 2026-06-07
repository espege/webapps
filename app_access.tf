# Required for reusable access groups with email lists
resource "cloudflare_zero_trust_list" "email_list" {
  for_each    = var.EMAIL_LISTS
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
  for_each   = local.access_group_with_email_lookups
  depends_on = [cloudflare_zero_trust_list.email_list]
  name       = "${title(lookup(each.value, "name", each.key))} - TF Access Group"
  account_id = cloudflare_account.my_account.id
  zone_id    = cloudflare_zone.personal_domain.id
  is_default = lookup(each.value, "is_default", false)
  include    = each.value.include
  require    = try(each.value.require, [])
  exclude    = try(each.value.exclude, [])
}

# Create the access policies from local
resource "cloudflare_zero_trust_access_policy" "access_policy" {
  for_each   = local.access_policies_with_lookups
  depends_on = [cloudflare_zero_trust_access_group.my_access_groups]

  account_id        = cloudflare_account.my_account.id
  name              = "${title(each.value.policy_name)} - TF Access Policy"
  decision          = each.value.decision
  session_duration  = each.value.session_duration
  approval_required = each.value.approval_required
  include           = each.value.include
  require           = each.value.require
  exclude           = each.value.exclude
}
