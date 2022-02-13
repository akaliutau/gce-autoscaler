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

variable "image" {
  default = "eu.gcr.io/message-multi-processor/processor:v1"
}

#####################################################################
# Modules
#####################################################################

module "gce" {
  source = "./gce"

  project = var.project
  region = var.region
  zone = var.zone
  image = var.image
}
