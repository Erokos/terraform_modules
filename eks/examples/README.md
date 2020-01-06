## Examples
These serve a few purposes:

1. Shows developers how to use the module in their "live infrastructure" repository in a straightforward way
 as integrated with other terraform community supported modules.
2. Provides a simple way to play with a Kubernetes cluster you create.
3. In the future it could be used as a test infrastructure for CI.

The folder `launch_configurations` shows a complete example of how to instantiate an EKS cluster using launch 
configurations with worker node auto scaling groups. The reason for having the option to use launch configurations
is to achieve automatic updates of any part of the cluster and ultimately to achieve "zero-downtime" deployments.

For now this isn't possible to achieve by using launch templates because of the issue described in the "Known Issues"
section of the README file in the `eks` module folder. Nevertheless launch templates give many more configurable
options and should be preferred, especially when the issue with them is resolved.
A full working example of using launch templates is given in the `launch_templates` folder.

A new feature was very recently launched, called node groups. This feature turns EKS into a fully managed service as
the data plane, i.e. worker nodes, is also managed by AWS. AWS makes sure the nodes are connected and authenticated
to the control plane, i.e. the master nodes. This works like a charm, the only problem is, there is still no mention
of using spot instances. How to leverage node groups is described in the `node_groups` folder.
