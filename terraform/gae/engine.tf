#####################################################################
# GCE Provider
#####################################################################
resource "google_service_account" "gce_default_sa" {
  account_id   = "gce-base-sa-1"
  display_name = "GCE Default Service Account"
  project = var.project
}

resource "google_service_account_iam_binding" "editor-role-sa-iam" {
  service_account_id = google_service_account.gce_default_sa.name
  role               = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.gce_default_sa.email}",
  ]
}


