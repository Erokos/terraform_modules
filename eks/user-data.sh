#!/bin/bash -xe

if [[ -z ${node_label} ]]; then
    /etc/eks/bootstrap.sh --use-max-pods true --b64-cluster-ca ${kubeconfig_cert_auth_data} \
    --apiserver-endpoint ${cluster_endpoint} ${cluster_name}
else
    /etc/eks/bootstrap.sh --use-max-pods true --b64-cluster-ca ${kubeconfig_cert_auth_data} \
    --apiserver-endpoint ${cluster_endpoint} ${cluster_name} --kubelet-extra-args --node-labels='${node_label},ami_id=${ami_id}'
fi
