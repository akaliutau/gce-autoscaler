#####################################################################
# GCE Provider
#####################################################################
resource "google_service_account" "gce_default_sa" {
  account_id   = "gce-default-sa"
  display_name = "GCE Default Service Account"
}


