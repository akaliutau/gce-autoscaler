resource "google_pubsub_topic" "incoming_files" {
  count = 1
  name = "incoming_files"
}

resource "google_pubsub_subscription" "incoming_files" {
  count = 1
  name = "incoming_files"
  topic = google_pubsub_topic.incoming_files[0].name
  ack_deadline_seconds = 600
  labels = {
    subscription_id = "incoming_files"
  }

  expiration_policy {
    ttl = "" # never
  }
}

resource "google_pubsub_topic" "processed_files" {
  count = 1
  name = "processed_files"
}

resource "google_pubsub_subscription" "processed_files" {
  count = 1
  name = "processed_files"
  topic = google_pubsub_topic.processed_files[0].name
  ack_deadline_seconds = 600

  expiration_policy {
    ttl = "" # never
  }
}
