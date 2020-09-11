variable "subscription_prefix" {
  type        = string
  description = "The subscription prefix. E.g. the 'dev'."
}

variable "location_prefix" {
  type        = string
  description = "The location prefix. E.g. the Azure location uksouth has the prefix 'uks'"
}

variable "apim_name" {
  type        = string
  description = "The name of the API Management instance containg the API to manage"
}

variable "apim_resource_group" {
  type        = string
  description = "The resource group in which the API Management instance exists"
}

variable "api_display_name" {
  type        = string
  description = "The display name of the API being managed"
}

variable "api_name" {
  type        = string
  description = "The name of the API being managed"
}

variable "api_path" {
  type        = string
  description = "The path of the API being managed"
}

variable "api_service_url" {
  type        = string
  description = "Absolute URL of the backend service implementing this API."
}

variable "api_versionset_name" {
  type        = string
  description = "Name of the API Version Set, if one is required"
  default     = ""
}

variable "api_versionset_displayname" {
  type        = string
  description = "Display name of the API Version Set, if one is required"
  default     = ""
}

variable "api_is_versioned" {
  type        = bool
  description = "Indicates whether this API is versioned"
}

variable "apim_product" {
  type = set(object({
    description           = string   
    product_id            = string
    display_name          = string   
    approval_required     = bool   
    published             = bool    
    subscription_required = bool
  }))
  default     = []
  description = "APIM Product"
}

variable "apim_users" {
  type = set(object({
    user_id               = string   
    first_name            = string
    last_name             = string   
    email                 = string   
    confirmation          = string    
  }))
  default     = []
  description = "APIM Users"
}

variable "apim_groups" {
  type = set(object({
    display_name  = string   
    name          = string
    description   = string   
  }))
  default     = []
  description = "APIM Groups"
}

variable "apim_group_users" {
  type = set(object({
    user_id     = string   
    group_name  = string
  }))
  default     = []
  description = "APIM Users to assign to Groups"
}

variable "apim_product_group" {
  type = set(object({
    product_id  = string   
    group_name  = string
  }))
  default     = []
  description = "APIM Groups to assign to Products"
}

variable "api-versions" {
  type = set(object({
    version               = string   
    api_name              = string
    api_display_name      = string
    api_path              = string
    api_service_url       = string  
    subscription_required = bool
    product_id            = string    
  }))
  default     = []
  description = "An API, may be related to a version set"
}

variable "api-operations" {
  type = set(object({   
    display_name        = string 
    method              = string
    operation_id        = string    
    url_template        = string
    description         = string
    api_name            = string
    parameter           = set(object({
      name        = string
      required    = bool
      type        = string
      description = string
    }))
    request             = set(object({      
      description = string
      content_type = string
      sample = string      
    }))
    response             = set(object({      
      description   = string
      status_code   = number
      representation = set(object({
          content_type  = string
          sample        = string      
      }))      
    }))    
  }))
  default     = []
  description = <<EOF
  A set of operations to manage within the API. 
  - display_name: The display name of the operation
  - method: POST, GET etc
  - operation_id: The operation_id of the operation, often a lowercase version of the display_name
  - url_template: Can be something like delivery or include a parameter(s), like delivery/{deliveryId}, if you include parameters you need to fill out the parameter variable. If you need more than one parameter then code that on your own, I'm done !
  EOF  
}

variable "api-policy" {
  type = set(object({  
    api_name            = string   
    xml_content         = string
  }))
  default     = []
  description = <<EOF
  A set of policy locations, one per operation. This is XML and is passed to the module as a file
  - operation_id: The operation_id of the operation this policy relates to
  - xml_content: The path to the file containing the policy XML
  EOF
}

variable "operation-policies" {
  type = set(object({  
    operation_id        = string   
    xml_content         = string
  }))
  default = []
  description = <<EOF
  A set of policy locations, one per operation. This is XML and is passed to the module as a file
  - operation_id: The operation_id of the operation this policy relates to
  - xml_content: The path to the file containing the policy XML
  EOF
}

variable "operation-fa-backends" {
  type = set(object({
        operation         = string
        name              = string
        description       = string  
        function_app_id   = string       
        function_app_name = string        
        function_app_rg   = string
        url               = string
  }))
  default     = []
  description = <<EOF
  A set of function app backends, one per operation requiring a function app backend. Note that more than one operation can share the same backend
  - operation: The operation_id of the operation this backend relates to. This is purely for descriptive purposes, it's not used anywhere
  - name: The name of the backend, note that this name needs to be referenced in the policy XML like this -  <set-backend-service id="apim-generated-policy" backend-id="backend1" />
  - description: Generally the same as the name
  - function_app_name: The name of the function app for this backend
  - function_app_rg: The resource group the function app to be called lives in. Note, this must be in the same subscription as the APIM 
  - url: The url of the function app HTTP endpoint, but without any parts you have defined in the operation url_template
  EOF
}

variable "operation-la-backends" {
  type = set(object({
        name            = string
        description     = string  
        logic_app_name  = string      
        la_resource_group  = string                
  }))
  default     = []
  description = <<EOF
  A set of logic app backends, one per operation requiring a logic app backend. Note that more than one operation can share the same backend
  - name: The name of the backend, note that this name is referenced in the policy XML
  - description: Generally the same as the name
  - resource_group: The resource group the logic app lives in. Note, this must be in the same subscription as the APIM
  - url: The trigger URL for the logic app, you can see this in the logic app designer only once the logic app is created. You can also get it from an ARM template as an output variable, or from Terraform as similar
  EOF
}

variable "namedvalues" {
  type = set(object({
    display_name    = string
    name            = string   
    secret          = bool    
    value           = string
  }))
  default     = []
  description = <<EOF
  Named values are key/value pairs used by APIM to store various bits of data. Generally these are referenced from policies, anything {{some_name_here}} is a named value.
  - display_name: The name of the named value, this is the name used in policies etc
  - name: The name of the named value as APIM sees it, often just a GUID
  - secret: True/False, True is the value is a secret or sensitive
  - value: The value of the named value
  EOF
}
