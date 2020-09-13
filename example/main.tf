
variable "region" {
  description = "This is the cloud hosting region where your webapp will be deployed."
  default = "ap-southeast-2"
}

variable "profile" {
  description = "This is the profile names to use with AWS."
}

variable "upload_directory" {
  type = string
  default = "../build"
}

variable "sub_domain" {
  description = "The single hierachy sub domain this site is being published in (e.g. qa, prod, dev)"
}

variable "domain_name" {
  description = "Base domain name to use"
}

variable "route53_zone_id" {
  description = "Route 53 Zone ID of the base domain. Haven't worked out on how to fetch that automatically"
}

variable "environment" {
  description = "Environment description used in tags and summaries"
}


# AWS Region for S3 and other resources
provider "aws" {
  region = var.region
  profile = var.profile
  alias = "main"
}

# AWS Region for ACM (Cloudfront requires ACM certs to be available in us-east-1)
provider "aws" {
  region = "us-east-1"
  profile = var.profile
  alias = "acm"
}

# Need to create a non-aliased provider to remove Error: Missing required argument
# https://github.com/terraform-providers/terraform-provider-aws/issues/9989
provider "aws" {
  region = var.region
  profile = var.profile
}

# Setting everything up
module "s3-spa-website" {
  source = "./.."

  upload_directory = var.upload_directory
  sub_domain = var.sub_domain
  domain_name = var.domain_name
  route53_zone_id = var.route53_zone_id

  providers = {
    aws.main = aws.main
    aws.acm = aws.acm
  }
}
