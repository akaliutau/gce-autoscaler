#!/bin/bash

gcloud compute instance-groups managed delete https://www.googleapis.com/compute/beta/projects/message-multi-processor/zones/europe-west2-c/instanceGroupManagers/proc-instance-group-1 --quiet
gcloud compute instance-templates delete https://www.googleapis.com/compute/v1/projects/message-multi-processor/global/instanceTemplates/proc-template-1 --quiet
gcloud compute firewall-rules delete https://www.googleapis.com/compute/v1/projects/message-multi-processor/global/firewalls/fwr-http-health-check --quiet
gcloud compute health-checks delete https://www.googleapis.com/compute/v1/projects/message-multi-processor/global/healthChecks/proc-http-health-check --quiet
gcloud pubsub topics delete projects/message-multi-processor/topics/incoming_files --quiet
gcloud pubsub subscriptions delete projects/message-multi-processor/subscriptions/incoming_files --quiet
gcloud pubsub topics delete projects/message-multi-processor/topics/processed_files --quiet
gcloud pubsub subscriptions delete projects/message-multi-processor/subscriptions/processed_files --quiet