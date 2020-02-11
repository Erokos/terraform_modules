#!/bin/bash

# Get a list of EKS worker nodes
nodes=$(kubectl get nodes --show-labels | tail -n +2 | tr " " ":")
nodes_to_drain=""
pos_params="$@"

# The label that's passed to the script, here called "designation"
# is of a format: <price_type>;<ami_id>;<instance_type> e.g:
# lifecycle=spot,worker-type=compute-optimized;ami-03772b2e67db0c87b;c5.large
for designation in $pos_params; do
  # create a label array
  labels=($(echo $designation | tr ";" " "))
  price_type=$(echo ${labels[0]})
  ami_id=$(echo ${labels[1]})
  instance_type=$(echo ${labels[2]})
  echo "The price type is ${price_type}, the ami is ${ami_id} and the instance type is ${instance_type}"

  # Iterate through node labels and decide which nodes to drain
  for node in ${nodes}; do
    if [[ "${node}" == *"${price_type}"* ]] && [[ "${node}" != *"${instance_type}"* || "${node}" != *"${ami_id}"* ]]; then
      node_to_drain=$(echo $node | awk -F ":" '{print $1}')
      echo "node to drain: $node_to_drain"
      echo ""
      nodes_to_drain="${node_to_drain} ${nodes_to_drain}"
    fi
  done

  for retiree in ${nodes_to_drain}; do
    sudo -u ec2-user kubectl drain "${retiree}" --ignore-daemonsets=true --delete-local-data --force
    sleep 60
  done
done
