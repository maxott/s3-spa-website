# Terraform Module to deploy a SPA via a CloudFront backed S3 bucket

This is a highly opinionated Terraform module for deploying a SPA hosted web site via an S3 bucket and backed by CloudFront. It also creates the required certificate and entries in Route53.

It does the following:

1. Create an S3 bucket named `"${var.sub_comain}.${domain_name}"`
1. Upload all local file in `var.upload_directory` to the above S3 bucket (using `var.mime_types`)
1. Creating a certificate for `"${var.sub_comain}.${domain_name}"` and validating it via Route53 (`var.route53_zone_id`)
1. Provision a CloudFront distribution for the above S3 bucket (with restricted S3 access IAM)
1. Adding 'A' record(s) to Route53 as alias for the above CloudFront distribution

**Note:** If `var.sub_domain` is set to `www` the certificate will be for domain name `var.domain_name` with an alternative subject name `"${var.sub_comain}.${domain_name}"`. There will also be the same two 'A' records added to the Route53.

## Usage

See the [README](example/README.md) in the [example](example) folder.

The [main.tf](example/main.tf) defines all required variables and a reference to
this module, the [common.auto.tfvars](example/common.auto.tfvars) sets the common variables, while each deployment variation, like for _staging_ is set in the respective [staging.auto.tfvars](example/staging.auto.tfvars).

For an `npm` or `yarn` managed development and the above mention script in a `tf` directory, I am using the following `scripts` in the `package.json` file:

```json
    "scripts": {
      ...
      "deploy:staging": "yarn build && pushd tf && terraform workspace select staging && terraform apply -var-file=staging.tfvars && popd",
      "destroy:staging": "pushd tf && terraform workspace select staging && terraform destroy -var-file=staging.tfvars && popd",
      "deploy:production": "yarn build && pushd tf && terraform workspace select production && terraform apply -var-file=production.tfvars && popd",
```

## Credits

I started out with [terraform-aws-s3-cloudfront-website](https://github.com/riboseinc/terraform-aws-s3-cloudfront-website/blob/master/LICENSE) and adapted it to my specific use case.

## Lame Disclaimer

This is my first attempt to use Terraform and I'm sure there are plenty of ways to improve this. If you have any suggestions, open an issue, or even better submit a PR.
