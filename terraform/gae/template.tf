module "gce-container" {

  source = "./../gce-container"

  container = {
    image = "gcr.io/message-multi-processor/processor:v1"
    env = [
      {
        name = "GOOGLE_CLOUD_PROJECT"
        value = "message-multi-processor"
      }
    ]
  }

  restart_policy = "Always"
}

resource "google_compute_instance_template" "processor_template" {
  name         = "proc-template-1"
  machine_type = "e2-medium"

  disk {
    source_image = join("/", [ "cos-cloud", reverse(split("/", module.gce-container.source_image))[0]])
    auto_delete  = true
    disk_size_gb = 10
    disk_type = "pd-balanced"
    type = "PERSISTENT"
    boot = true

    labels = {
      "container-vm" = module.gce-container.vm_container_label
    }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = "#!/bin/bash\ncurl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh\nsudo bash install-monitoring-agent.sh"

  metadata = {
    google-logging-enabled = "true"
    "gce-container-declaration" = module.gce-container.metadata_value
  }

  service_account {
    email = google_service_account.gce_default_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }


  can_ip_forward = false
}

resource "google_compute_target_pool" "default" {
  provider = google-beta
  name = "my-target-pool"
  region = var.region
}

resource "google_compute_instance_group_manager" "default" {
  provider = google-beta

  name = "processors-group"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.processor_template.id
    name              = "primary"
  }

  target_pools       = [google_compute_target_pool.default.id]
  base_instance_name = "autoscaler-sample"
}

resource "google_compute_autoscaler" "default" {
  provider = google-beta

  name   = "proc-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = incoming_files"
      target = 2
      type = "GAUGE"
    }
  }
}
