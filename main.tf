data "azurerm_subscription" "current" {}

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