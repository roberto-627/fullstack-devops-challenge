# In this file put the variables related to the deployment
variable "project_id" {
    type = "string"
    description = "GCP Project ID"
}

variable "region" {
    type = "string"
    description = "GCP Region"
}

variable "public_access" {
    type = bool
    description = "Determines wether the site is publicly accesible."
    default = false
}