# Base domain name. Subdomain, like 'staging' or 'www' are being defined separatedly
domain_name = "my.domain"

# The Route%3 Zone has to be already created
route53_zone_id = "ABC_REPLACE"

# AWS region to deploy in and authorization profile to use
region  = "ap-southeast-2"
profile = "myprofile"

# Location of all the files making up the web site
upload_directory = "./build/"
