# Create operations for the API
resource "azurerm_api_management_api_operation" "operations" {
  for_each = { for operation in var.api-operations : operation.operation_id => operation }

  api_management_name = var.apim_name
  api_name            = azurerm_api_management_api.api[each.value.api_name].name
  display_name        = each.value.display_name
  method              = each.value.method
  operation_id        = each.value.operation_id
  resource_group_name = var.apim_resource_group
  url_template        = each.value.url_template
  description         = each.value.description


   dynamic "template_parameter" {
  
    for_each = each.value.parameter

    content {
      name        = template_parameter.value.name
      required    = template_parameter.value.required
      type        = template_parameter.value.type
      description = template_parameter.value.description
    }
  }

  dynamic "request" {
  
    for_each = each.value.request

    content {
      description     = request.value.description
      representation {
        content_type  = request.value.content_type
        sample        = file(request.value.sample)
      }
    }
  }

  dynamic "response" {
  
    for_each = each.value.response

    content {
      description     = response.value.description
      status_code     = response.value.status_code
      dynamic "representation"{
        for_each = try(response.value.representation, [])
        content {
          content_type  = representation.value.content_type
          sample        = file(representation.value.sample)
        }
      }
    }    
  }
}

# Create policies for API
resource "azurerm_api_management_api_operation_policy" "policies" {
  for_each = { for policy in var.operation-policies : policy.operation_id => policy }

  api_management_name = var.apim_name
  api_name            = azurerm_api_management_api_operation.operations[each.value.operation_id].api_name
  operation_id        = azurerm_api_management_api_operation.operations[each.value.operation_id].operation_id
  resource_group_name = var.apim_resource_group
  xml_content         = file(each.value.xml_content)

  # The policy can include references to backends, if they don't exist when the policy is deployed
  # then Azure moans
  depends_on = [
    azurerm_api_management_backend.operation-la_backends,
    azurerm_api_management_backend.operation-fa_backends
  ]
}