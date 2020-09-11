resource "azurerm_api_management_user" "user" {
  for_each = { for apim_users in var.apim_users : apim_users.user_id => apim_users }
  api_management_name = var.apim_name
  resource_group_name = var.apim_resource_group
  user_id             = each.value.user_id
  first_name          = each.value.first_name
  last_name           = each.value.last_name
  email               = each.value.email
  confirmation        = each.value.confirmation
  state               = "active"
}

resource "azurerm_api_management_group" "group"{
  for_each = { for apim_groups in var.apim_groups : apim_groups.name => apim_groups }
  api_management_name = var.apim_name
  resource_group_name = var.apim_resource_group
  name                = each.value.name
  display_name        = each.value.display_name
  description         = each.value.description
  type                = "custom"
}

resource "azurerm_api_management_group_user" "group_user" {
  for_each = { for apim_group_users in var.apim_group_users : apim_group_users.user_id => apim_group_users }
  api_management_name = var.apim_name
  resource_group_name = var.apim_resource_group
  user_id             = each.value.user_id
  group_name          = each.value.group_name

  depends_on = [
    azurerm_api_management_group.group,
    azurerm_api_management_user.user
  ]
}