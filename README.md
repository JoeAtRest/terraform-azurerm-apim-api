# terraform-apim-api

## Deploys 1 API to Azure API Manager

This module deploys a single API to Azure API Manager with the following characteristics:

- Either a non versioned API or an API version set
- All operations for the API
- API level single policy or individual policies per operation
- Logic app backends, but you must create your policy files manually to support this
- Function app backends, but you must create your policy files manually to support this
- Named values can be created

## Simple Usage

Include the module in you main.tf file along with the variables you need to pass in

```hcl
module "terraform-apim-api" {
  source  = "JoeAtRest/apim-api/azurerm"
  subscription_prefix         = var.subscription_prefix
  location                    = var.location
  apim_name                   = var.apim_name
  apim_resource_group         = var.apim_resource_group
  api_display_name            = var.api_display_name
  api_name                    = var.api_name
  api_path                    = var.api_path
  api_service_url             = var.api_service_url
  api_versionset_name         = var.api_versionset_name
  api_versionset_displayname  = var.api_versionset_displayname
  api_is_versioned            = var.api_is_versioned
  
  api-versions                = var.api-versions
  api-operations              = var.api-operations
  api-policy                  = var.api-policy
  operation-policies          = var.operation-policies
  operation-fa-backends       = var.operation-fa-backends
  operation-la-backends       = var.operation-la-backends
  namedvalues                 = var.namedvalues
}
```

You can configure the module directly in the main.tf, like in this example configuration. This example pre-supposes that the API Manager referred  to already exists, as do the logic and function apps referenced, as well as the policy files.

```hcl
provider "azurerm" { 
  version = "~> 2.21.0"
  features {}  
}

terraform {
  backend "azurerm" {}
}

module "terraform-apim-api" {
  source  = "JoeAtRest/apim-api/azurerm"
  
  subscription_prefix         = "dev"
  location                    = "uks"
  apim_name                   = "my-test-apim"
  apim_resource_group         = "my-test-rg"
  
  api_display_name            = "My Test API"
  api_name                    = "mytestapi"
  api_path                    = "mytestapi"
  api_service_url             = ""

  api_is_versioned            = false
  
  api-versions                = []

  api-operations = [
    {
      display_name        = "Logic App Operation"
      method              = "POST"
      operation_id        = "logicappoperation"
      url_template        = "doit"
      description         = "Sends data to a logic app"
      api_name            = "my-test-apim"
      parameter           = {}
    },
    {
      display_name        = "Function App Operation"  
      method              = "GET"
      operation_id        = "functionappoperation"
      url_template        = "doit/{doingItId}"
      description         = "Calls a function app"
      api_name            = "my-test-apim"
      parameter           = {
        name        = "doingItId"
        required    = true
        type        = "string"
        description = "The ID of the thing"
      }
    }
  ]

  operation-policies = [
    {
      operation_id        = "functionappoperation"
      xml_content         = "./policies/demo-op-opfunctionapp.xml"
    },
    {
      operation_id        = "logicappoperation"
      xml_content         = "./policies/demo-op-oplogicapp.xml"
    }
  ]

  operation-fa-backends = [{
    operation          = "functionappoperation"
    name               = "fa-backend"
    description        = "A function app backend"
    function_app_name  = "my-function-app"
    function_app_rg    = "my-function-apps resource group"
    url                = "https://my-function-app.azurewebsites.net/api/"
  }]

  operation-la-backends = [{
    name              = "la-backend"
    description       = "A logic app backend"
    logic_app_name    = "my-logic-app"
    la_resource_group = "my-logic-apps resource group"
  }]

  namedvalues                 = []
}
```

If you are providing policy files then they need to exist in the locations specified in the xml_content fields.

### Function App Backends

This module will create the function app back end for you but it will not include the relevant lines in your policy file for the API or Operations. You must do this yourself. In this example the backend-id refers to the operation-fa-backends named backend1.

```xml
<inbound>
    <base />
    <set-backend-service id="apim-generated-policy" backend-id="backend1" />
</inbound>
```

### Logic App Backends

This module will create the logic app back end for you but it will not include the relevant lines in your policy file for the Operation. You must do this yourself. In this example the backend-id refers to the operation operation-la-backends named backend2. The named value, {{YOUR LOGIC APP NAME-sas}} is a named value created by this module, it holds the SAS key, and some other stuff I am unable to trim off, and is the name of your logic app with the suffix -sas.

```xml
<inbound>
    <base />    
    <set-backend-service id="apim-generated-policy" backend-id="backend2" />
    <set-method id="apim-generated-policy">POST</set-method>
    <rewrite-uri id="apim-generated-policy" template="/manual/paths/invoke/?api-version=2016-06-01&amp;{{YOUR LOGIC APP NAME-sas}}" />
    <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />
</inbound>
```

### Named Values

Rather than storing sensitve data directly in policy files you can refer to API-M named values instead. To use them, you must update your policy files and include the relevant configuration within the namedvalues variable.

First set up the variable in the module or in your .tfvars file.

```hcl
namedvalues = [{
 display_name    = "MyNamedValue"
 name            = "mynamedvalue"
 secret          = true
 value           = "This is a secret"
}]
```

Then edit your policy file to include the named value in the following format, note that counter intuitively you need to use the display name and not the actual name.

```xml
<somelocation pref="{{MyNamedValue}}" />
```
