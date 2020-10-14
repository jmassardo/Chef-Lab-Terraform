# THIS REPO IS ARCHIVED AND ONLY KEPT FOR HISTORICAL CONTEXT

Please use the `chef-automate` based installs for any new labs or deployments, do not follow this pattern. I'm only keeping it so I remember how I did certain things in bash scripts and Terraform.

## Info

This repo contains bits to stand up a separate Chef Server, Chef Automate Server, Jenkins Server, and test nodes (linux and windows). It copies a local instance of a `chef-repo` folder and bootstrap scripts to the Jenkins server then bootstraps the nodes, some using roles/environments and some with policyfiles/policy groups.
