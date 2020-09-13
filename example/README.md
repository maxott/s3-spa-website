# Example

This directory contains the configuration files for deploying a _staging_ , as well as a _production_ environment. The common parameters, like the base domain name, or authorization information are defined in `common.auto.tfvars`. Please change them to fit your environment.

The different deployment settings can be found in `staging.tfvars` and `production.tfvars`. Obviously, you can easily add additional ones. The content of those two files should be self explanatory.

## Usage

We are using Terraform's workspaces to deploy the different configurations. You'll need to create them first (`terraform workspace new --help`).

Then to deploy __staging__ for instance:

    terraform workspace select staging \
    && terraform apply -var-file=staging.tfvars

Or for __production__:

    terraform workspace select production \
    && terraform apply -var-file=production.tfvars

As expected, destroying works the same.
