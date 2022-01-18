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

#####################################################################
# Modules
#####################################################################


module "gae" {
  source = "./gae"

  project = var.project
  region = var.region
  zone = var.zone
}
