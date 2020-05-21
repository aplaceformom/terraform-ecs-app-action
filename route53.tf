resource "aws_route53_record" "default" {
  zone_id = local.zone_id
  name    = var.github_project
  type    = "A"

  alias {
    name                    = module.ecs.lb["dnsname"]
    zone_id                 = module.ecs.lb["zone_id"]
    evaluate_target_health  = true
  }
}
