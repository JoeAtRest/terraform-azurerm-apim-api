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