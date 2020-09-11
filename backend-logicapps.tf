# Deploys an ARM Template to retrieve the SAS Key for any logic apps
resource "azurerm_template_deployment" "logic_app_triggers1" {
    for_each            = { for backend in var.operation-la-backends : backend.logic_app_name => backend }
    
    name                = "javafunckey${each.value.logic_app_name}221"
    resource_group_name = each.value.la_resource_group
    deployment_mode     = "Incremental"
    parameters = {
        "logicApp" = each.value.logic_app_name
    }                          
    template_body = file("${path.module}/logicapptriggerarm.json")
}

# Retrieves data about the logic apps we want to use in the backend
data "azurerm_logic_app_workflow" "logic_apps" {
  for_each            = { for backend in var.operation-la-backends : backend.logic_app_name => backend }
  name                = each.value.logic_app_name
  resource_group_name = each.value.la_resource_group
}

# Create logic app backends for the API
resource "azurerm_api_management_backend" "operation-la_backends" {
  for_each = { for backend in var.operation-la-backends : backend.name => backend }

  api_management_name = var.apim_name
  description         = each.value.description
  name                = each.value.name
  protocol            = "http"
  resource_group_name = var.apim_resource_group
  resource_id         = "https://management.azure.com${data.azurerm_logic_app_workflow.logic_apps[each.value.logic_app_name].id}"
  url                 = "${data.azurerm_logic_app_workflow.logic_apps[each.value.logic_app_name].access_endpoint}/triggers"
  
}

# Creates the namedvalues which the policy file must refer to
resource "azurerm_api_management_named_value" "latriggers" {
  for_each            = { for backend in var.operation-la-backends : backend.logic_app_name => backend }

  api_management_name = var.apim_name
  display_name        = "${each.value.logic_app_name}-sas"
  name                = "${each.value.logic_app_name}-sas"
  resource_group_name = var.apim_resource_group
  secret              = true
  value               = lookup(azurerm_template_deployment.logic_app_triggers1[each.value.logic_app_name].outputs, "sasToken")
  
  timeouts {}
}