#!/bin/bash -xe  

# Install python 3
sudo yum update -y
sudo yum install -y python36.x86_64

# Install Git just in case
sudo yum install -y git

# Get the latest pip and install it
cd /home/ec2-user && curl -O https://bootstrap.pypa.io/get-pip.py
sudo -u ec2-user python3 get-pip.py --user
sudo -u ec2-user pip install --upgrade pip --user
export PATH=/home/ec2-user/.local/bin:$PATH && sudo -u ec2-user echo "export PATH=/home/ec2-user/.local/bin:$PATH" >> /home/ec2-user/.bashrc
source ~/.bashrc

# Get the aws-iam-authenticator binary
curl -O ${iam_authenticator_link}
chmod +x ./aws-iam-authenticator
mkdir -p /home/ec2-user/bin
mv ./aws-iam-authenticator bin/

# Upgrade the AWS CLI version
sudo -u ec2-user pip install awscli --upgrade --user

# Create the authentication configmap
{
    echo "apiVersion: v1"
    echo "kind: ConfigMap"
    echo "metadata:"
    echo "  name: aws-auth"
    echo "  namespace: kube-system"
    echo "data:"
    echo "  mapRoles: |"
    echo "    - rolearn: ${eks_node_role_arn}"
    echo "      username: system:node:{{EC2PrivateDNSName}}"
    echo "      groups:"
    echo "        - system:bootstrappers"
    echo "        - system:nodes"
    echo "    - rolearn: ${bastion_role_arn}"
    echo "      username: ${bastion_name}"
    echo "      groups:"
    echo "        - system:masters"

} >> aws-auth-cm.yaml

# Download kubectl
curl -o kubectl ${kubectl_eks_link}
chmod +x ./kubectl
mv ./kubectl /bin/kubectl

# Create the kubeconfig and authenticate the nodes and bastion
sudo -u ec2-user aws eks --region "${region_name}" update-kubeconfig --name "${cluster_name}"
kubectl apply -f aws-auth-cm.yaml

# Apply the specified CNI version
kubectl apply -f ${cni_link}
