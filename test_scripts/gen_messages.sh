#!/bin/bash

for (( c=1; c<=$1; c++ ))
do
  msg="{\"id\":\"$c\"}"
  gcloud pubsub topics publish "incoming_files" --message="$msg"
done
