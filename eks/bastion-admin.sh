#!/usr/bin/env bash
set -e

sleep 2m
bastion_after_workers_ng="$1"
cni_link="$2"


if [[ "${bastion_after_workers_ng}" != "true" ]]; then
  kubectl apply -f aws-auth-cm.yaml
  # Apply the specified CNI version
  kubectl apply -f ${cni_link}
fi