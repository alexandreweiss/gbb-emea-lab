variable "subscription_id" {
    description = "Subscription ID to deploy lab to"
}

variable "client_id" {
    description = "Client Id of the SPN used to deploy resources"
}

variable "client_secret" {
    description = "Secret of the Client Id of the SPN used to deploy resources"
}

variable "tenant_id" {
    description = "Tenant Id of the Client Id of the SPN used to deploy resources"
}

variable "resource_group_name" { 
    default = "routing-lab"
}

variable "location" { 
    description = "Physical location where resource are deployed"
    default = "francecentral"
}

variable "short_location" {
    description = "Friendly location name used in components naming"
    default = "frc"
}
