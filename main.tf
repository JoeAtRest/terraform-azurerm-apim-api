data "azurerm_subscription" "current" {}

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

resource "azurerm_api_management_product" "product" {
  for_each = { for apim_product in var.apim_product : apim_product.product_id => apim_product }
  api_management_name   = var.apim_name
  resource_group_name   = var.apim_resource_group
  product_id            = each.value.product_id
  description           = each.value.description
  display_name          = each.value.display_name
  approval_required     = each.value.approval_required
  published             = each.value.published
  subscription_required = each.value.subscription_required  
}

resource "azurerm_api_management_product_group" "product_group" {
  for_each = { for apim_product_group in var.apim_product_group : apim_product_group.product_id => apim_product_group }
  api_management_name   = var.apim_name
  resource_group_name   = var.apim_resource_group
  product_id            = each.value.product_id
  group_name            = each.value.group_name

  depends_on = [
    azurerm_api_management_group.group,
    azurerm_api_management_product.product
  ]
}

# Create an API Version set
resource "azurerm_api_management_api_version_set" "versionset" {
  name                = var.api_versionset_name
  resource_group_name = var.apim_resource_group
  api_management_name = var.apim_name
  display_name        = var.api_versionset_displayname
  versioning_scheme   = "Segment"
  count               = var.api_is_versioned ? 1 : 0
}

# Create API
resource "azurerm_api_management_api" "api" {
  for_each = { for api in var.api-versions : api.api_name => api }

  api_management_name = var.apim_name
  display_name        = each.value.api_display_name
  name                = each.value.api_name
  path                = each.value.api_path
  service_url         = each.value.api_service_url
  protocols = [
    "https",
  ]
  resource_group_name   = var.apim_resource_group
  revision              = "1"
  soap_pass_through     = false
  version               = var.api_is_versioned ? each.value.version : null
  version_set_id        = var.api_is_versioned ? azurerm_api_management_api_version_set.versionset[0].id : null
  subscription_required = each.value.subscription_required
  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }
}

resource "azurerm_api_management_product_api" "product_api" {
  for_each = { for api in var.api-versions : api.api_name => api }

  api_management_name = var.apim_name
  resource_group_name = var.apim_resource_group
  api_name            = each.value.api_name
  product_id          = each.value.product_id

  depends_on = [
    azurerm_api_management_api.api,
    azurerm_api_management_product.product
  ]
}

# Set an API policy, if there is one
resource "azurerm_api_management_api_policy" "api_policy" {
    for_each = { for api-policy in var.api-policy : api-policy.api_name => api-policy }

  api_name            = azurerm_api_management_api.api[each.value.api_name].name
  api_management_name = azurerm_api_management_api.api[each.value.api_name].api_management_name
  resource_group_name = azurerm_api_management_api.api[each.value.api_name].resource_group_name

  xml_content = file(each.value.xml_content)

  # The policy can include references to backends, if they don't exist when the policy is deployed
  # then Azure moans
  depends_on = [
    azurerm_api_management_backend.operation-la_backends,
    azurerm_api_management_backend.operation-fa_backends
  ]
}

# Create named values used by the API
resource "azurerm_api_management_named_value" "namedvalues" {
  for_each = { for namedvalue in var.namedvalues : namedvalue.name => namedvalue }

  api_management_name = var.apim_name
  display_name        = each.value.display_name
  name                = each.value.name
  resource_group_name = var.apim_resource_group
  secret              = each.value.secret
  value               = each.value.value
  tags = [
    "key",
    "function",
    "auto",
  ]

  timeouts {}
}