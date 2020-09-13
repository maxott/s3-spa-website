variable "upload_directory" {
  type = string
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
  default = "development"
}

variable "mime_types" {
  default = {
    txt  = "text"
    htm   = "text/html"
    html  = "text/html"
    css   = "text/css"
    csv   = "text/csv"
    md    = "text/markdown"
    ttf   = "font/ttf"
    js    = "application/javascript"
    map   = "application/javascript"
    json  = "application/json"
    gif   = "image/gif"
    png   = "image/png"
    PNG   = "image/png"
    jpeg  = "image/jpeg"
    ico   = "image/x-icon"
    webp  = "image/webp"
    svg   = "image/svg+xml"
  }
}
