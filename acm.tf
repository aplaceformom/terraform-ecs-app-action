/* vim: ts=2:sw=2:sts=0:expandtab */

# Strip any trailing `.` from the name: https://bugzilla.mozilla.org/show_bug.cgi?id=134402
# Note: AWS ACM automatically strips the trailing `.`, but Terraform doesn't
# know this and so it causes drift between the internal resource cache in
# Terraform and the resource as returned by AWS (which isn't picked up until
# the next `terraform refresh`).
data "aws_route53_zone" "selected" {
  zone_id = local.zone_id
}

locals {
  certificate = var.certificate == "" ? aws_acm_certificate.cert[0].arn : data.aws_acm_certificate.selected[0].arn
  cert_dvo    = var.certificate == "" ? aws_acm_certificate.cert[0].domain_validation_options : []
  alt_names   = var.certificate_alt_names != "" ? split(",", var.certificate_alt_names) : []
}

data "aws_acm_certificate" "selected" {
  count  = var.certificate == "" ? 0 : 1
  domain = var.certificate
}

resource "aws_acm_certificate" "cert" {
  count             = var.certificate == "" ? 1 : 0
  domain_name       = "${local.name}.${replace(data.aws_route53_zone.selected.name, "/[.]$/", "")}"
  validation_method = "DNS"

  tags = {
    app     = local.name
    repo    = var.github_repository
    project = var.project_name
    owner   = var.project_owner
    email   = var.project_email
  }

  # Note: AWS ACM automatically includes the domain_name in the Subject Alternative Names
  subject_alternative_names = local.alt_names

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_record" {
  for_each = {
    for dvo in local.cert_dvo :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 300
  type    = each.value.type
  zone_id = var.dns_zone_id_public # must be public
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count                   = var.certificate == "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_record : record.fqdn]
}
