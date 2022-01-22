#####################################################################
# GCE Provider
#####################################################################
resource "google_service_account" "gce_default_sa" {
  account_id   = "gce-base-sa-1"
  display_name = "GCE Default Service Account"
  project = var.project
}

resource "google_project_iam_member" "editor-role-sa-iam" {
  project = var.project
  role               = "roles/editor"
  member = "serviceAccount:${google_service_account.gce_default_sa.email}"
}


