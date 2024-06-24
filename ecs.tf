data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name       = var.name != "" ? "${var.github_project}-${var.name}" : var.github_project
  account_id = "${data.aws_caller_identity.current.account_id}"
  region     = "${data.aws_region.current.name}"
  ecr_repo   = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
  image      = var.image != "" ? var.image : "${local.ecr_repo}/${var.github_project}"
  policies   = var.policies != "" ? split(",", var.policies) : []
  zone_id    = var.public ? var.dns_zone_id_public : var.dns_zone_id_private

  cluster = {
    id                   = var.cluster_id
    name                 = var.cluster_cluster_name
    cluster_name         = var.cluster_cluster_name
    service_namespace_id = var.cluster_service_namespace_id
    region               = var.cluster_region
    vpc_id               = var.cluster_vpc_id
    public_subnets       = var.cluster_public_subnets
    private_subnets      = var.cluster_private_subnets
    security_groups      = var.cluster_security_groups
    execution_role_arn   = var.cluster_execution_role_arn
    elk_endpoint         = var.cluster_elk_endpoint
  }
}

resource "aws_iam_role" "ecs" {
  name               = "${local.name}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy" "selected" {
  count = length(local.policies)
  arn   = substr(local.policies[count.index], 0, 8) == "arn:aws:" ? local.policies[count.index] : "arn:aws:iam::${var.account_id}:policy/${local.policies[count.index]}"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count      = length(local.policies)
  role       = aws_iam_role.ecs.name
  policy_arn = data.aws_iam_policy.selected[count.index].arn
}

module "ecs" {
  source = "github.com/aplaceformom/terraform-ecs-app"

  name    = local.name
  prefix  = var.prefix != "" ? var.prefix : substr(local.name, 0, 6)
  family  = var.project_name
  image   = "${local.image}:${var.label}"
  memory  = var.mem
  cpus    = var.cpu
  public  = var.public
  cluster = local.cluster
  region  = var.region

  task_role_arn = aws_iam_role.ecs.arn

  enable_autoscaling             = var.autoscaling
  desired_count                  = var.autoscaling_min
  autoscaling_min_count          = var.autoscaling_min
  autoscaling_max_count          = var.autoscaling_max
  autoscaling_target_cpu         = var.autoscaling_target_cpu
  autoscaling_target_mem         = var.autoscaling_target_mem
  autoscaling_scale_out_cooldown = var.autoscaling_cooldown

  port        = var.target_port
  tg_protocol = var.target_protocol

  lb_port     = var.listener_port
  lb_protocol = var.listener_protocol
  certificate = local.certificate

  health_check_port         = var.target_port
  health_check_path         = var.health_check_path
  health_check_timeout      = var.health_check_timeout
  health_check_interval     = var.health_check_interval
  health_check_grace_period = var.health_check_grace_period

  security_group_ids = [aws_security_group.self.id]

  environment = var.environment
  secrets     = var.secrets

  service_level_settings = var.service_level_settings

  tags = {
    app     = local.name
    repo    = var.github_repository
    project = var.project_name
    owner   = var.project_owner
    email   = var.project_email
  }
}
