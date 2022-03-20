#!/bin/bash
curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh
sudo bash install-monitoring-agent.sh
mkdir -p /etc/systemd/system/docker.service.d
printf "[Service]\nExecStop=/bin/sh -c 'docker stop --time 90 \$(docker ps -q) | sleep 90s'\nKillMode=processes\nKillSignal=SIGTERM\nSuccessExitStatus=0" > /etc/systemd/system/docker.service.d/override.conf
