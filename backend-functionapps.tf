#data "azurerm_function_app" "function_apps" {
#  for_each            = { for backend in var.operation-fa-backends : backend.function_app_name => backend }
#  name                = each.value.function_app_name
#  resource_group_name = each.value.function_app_rg
#}

# Get the functions keys out of the app
resource "azurerm_template_deployment" "function_keys" {
  for_each = { for backend in var.operation-fa-backends : backend.function_app_name => backend }

    name        = "javafunckey${each.value.function_app_name}"
    parameters  = {
        "functionApp" = each.value.function_app_name
    }
    resource_group_name = each.value.function_app_rg
    deployment_mode     = "Incremental"    
    template_body = file("${path.module}/functionappkeysarm.json")
}

# Create function app backends of the API
resource "azurerm_api_management_backend" "operation-fa_backends" {
  for_each = { for backend in var.operation-fa-backends : backend.name => backend }

  api_management_name = var.apim_name
  description         = each.value.description
  name                = each.value.name
  protocol            = "http"
  resource_group_name = var.apim_resource_group
  resource_id         = "https://management.azure.com${each.value.function_app_id}"
  url                 = each.value.url
  credentials {
    certificate = []
    header = {
      "x-functions-key" = lookup(azurerm_template_deployment.function_keys[each.value.function_app_name].outputs, "functionkey")
    }
    query = {}
  }
}