locals {
  cos_image_family       = var.cos_image_name == null ? "cos-${var.cos_image_family}" : null
  cos_project            = "cos-cloud"
  invalid_restart_policy = var.restart_policy != "OnFailure" && var.restart_policy != "UnlessStopped" && var.restart_policy != "Always" && var.restart_policy != "No" ? 1 : 0

  spec = {
    spec = {
      containers    = [var.container]
      volumes       = var.volumes
      restartPolicy = var.restart_policy
    }
  }

  spec_as_yaml = yamlencode(local.spec)
}

data "google_compute_image" "coreos" {
  family  = local.cos_image_family
  project = local.cos_project
}
