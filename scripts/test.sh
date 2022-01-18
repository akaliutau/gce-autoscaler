#!/bin/bash

cos_image_name=$(gcloud compute images list --project cos-cloud --filter cos-stable --no-standard-images | awk 'NR == 2 {print $1}')
