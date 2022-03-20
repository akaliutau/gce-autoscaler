#####################################################################
# Global variables
#####################################################################
variable "project" {
  default = ""
}
variable "region" {
  default = "europe-west2"
}
variable "zone" {
  default = "europe-west2-c"
}

variable "google_app_creds" {
  default = ""
}

variable "ver" {
  default = "9b02f642"
}

variable "env" {
  default = "./scripts/env.template"
}

#####################################################################
# Modules
#####################################################################

module "gce" {
  source = "./gce"

  project = var.project
  region = var.region
  zone = var.zone
  ver = var.ver
  env = var.env
}
