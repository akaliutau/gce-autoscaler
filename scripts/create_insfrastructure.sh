#!/bin/bash

export THIS=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export PROJECT=message-multi-processor
export REGION=europe-west2
export ZONE=europe-west2-c
export APP_IMAGE=eu.gcr.io/message-multi-processor/processor:v1

echo creating pubsub resources
gcloud pubsub topics create incoming_files \
        --message-retention-duration=30d

gcloud pubsub subscriptions create incoming_files \
        --topic=incoming_files \
        --ack-deadline=600 \
        --message-retention-duration=7d

gcloud pubsub topics create processed_files \
        --message-retention-duration=30d

gcloud pubsub subscriptions create processed_files \
        --topic=incoming_files \
        --ack-deadline=600 \
        --message-retention-duration=7d


echo updating firewall rules
gcloud compute firewall-rules create fwr-http-health-check \
        --allow=tcp:8080 \
        --source-ranges=130.211.0.0/22,35.191.0.0/16 \
        --network=default \
        --source-tags=allow-firewall-check

# COS_IMAGE should look like cos-stable-93-16623-39-40
COS_IMAGE=$(gcloud compute images list --project cos-cloud --filter "cos-stable" --no-standard-images --format="table(NAME)" | awk 'NR == 2 {print $1}')
echo using COS_IMAGE=$COS_IMAGE

if [[ "$COS_IMAGE" == "" ]]; then
  echo cannot find a suitable COS image in gcloud
  exit 1
fi

SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter="EMAIL:compute@developer.gserviceaccount.com" --format="table(EMAIL)" | awk 'NR == 2 {print $1}')
echo using SERVICE_ACCOUNT=$SERVICE_ACCOUNT

if [[ "$SERVICE_ACCOUNT" == "" ]]; then
  echo cannot find default compute service account in gcloud
  exit 1
fi

echo creating health check
gcloud compute health-checks create http proc-http-health-check \
        --check-interval="30s"  \
        --healthy-threshold=3 \
        --unhealthy-threshold=3 \
        --port=8080 \
        --request-path="/health" \
        --timeout="15s"

scopes=(
  "https://www.googleapis.com/auth/devstorage.read_only"
  "https://www.googleapis.com/auth/logging.write"
  "https://www.googleapis.com/auth/monitoring"
  "https://www.googleapis.com/auth/pubsub"
  "https://www.googleapis.com/auth/compute"
  "https://www.googleapis.com/auth/service.management.readonly"
  "https://www.googleapis.com/auth/servicecontrol"
  "https://www.googleapis.com/auth/trace.append"
  "https://www.googleapis.com/auth/cloudplatformprojects.readonly"
  "https://www.googleapis.com/auth/cloud-platform"
)

scopes_line=$(IFS=, ; echo "${scopes[*]}")

##
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create-with-container?hl=en_US
#
echo creating instance-template
gcloud compute instance-templates create-with-container proc-template-1 \
        --project=$PROJECT \
        --machine-type=e2-micro \
        --network-interface=network=default,network-tier=PREMIUM,address="" \
        --maintenance-policy=MIGRATE \
        --service-account=$SERVICE_ACCOUNT \
        --scopes=$scopes_line \
        --tags=allow-firewall-check,http-server \
        --container-image=$APP_IMAGE \
        --container-restart-policy=always \
        --container-env=GOOGLE_CLOUD_PROJECT=$PROJECT \
        --container-tty \
        --metadata-from-file=startup-script=$THIS/startup_script.sh \
        --boot-disk-device-name=persistent-disk-0 \
        --boot-disk-size=10 \
        --boot-disk-type=pd-balanced \
        --image=projects/cos-cloud/global/images/$COS_IMAGE \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=container-vm=$COS_IMAGE \
        --region=$REGION

echo creating instance-group
gcloud compute instance-groups managed create proc-instance-group-1 \
        --project=$PROJECT \
        --zone=$ZONE \
        --base-instance-name=proc-instance \
        --size=1 \
        --template=proc-template-1 \
        --health-check=proc-http-health-check \
        --initial-delay=300

echo creating autoscaling policy
gcloud beta compute instance-groups managed set-autoscaling proc-instance-group-1 \
        --project=$PROJECT \
        --zone=$ZONE \
        --cool-down-period=60 \
        --max-num-replicas=5 \
        --min-num-replicas=1 \
        --mode=on \
        --stackdriver-metric-filter=resource.label.subscription_id\ =\ \"incoming_files\"\ AND\ resource.type\ =\ \"pubsub_subscription\" \
        --update-stackdriver-metric=pubsub.googleapis.com/subscription/num_undelivered_messages \
        --stackdriver-metric-utilization-target=2.0 \
        --stackdriver-metric-utilization-target-type=gauge \
        --scale-in-control=max-scaled-in-replicas-percent=80,time-window=300

echo done