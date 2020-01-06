#!/usr/bin/env bash

new_ami_id="$1"

# Prevent new pods from being scheduled to that node
sudo -u ec2-user kubectl cordon --selector "ami_id!=${new_ami_id}"

nodes=$(sudo -u ec2-user kubectl get nodes --selector "ami_id!=${new_ami_id}" -o json | jq -r '.items[].metadata.name')

for node in ${nodes}; do
  sudo -u ec2-user kubectl drain "${node}" --ignore-daemonsets=true --delete-local-data --force
  sleep 60
done
