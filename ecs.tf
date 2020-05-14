data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = "${data.aws_caller_identity.current.account_id}"
  region     = "${data.aws_region.current.name}"
  ecr_repo   = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.name}"
  policies   = split(",", var.policies)

  cluster    = {
    id                   = var.cluster_id
    service_namespace_id = var.cluster_service_namespace_id
    region               = var.cluster_region
    vpc_id               = var.cluster_vpc_id
    public_subnets       = var.cluster_public_subnets
    private_subnets      = var.cluster_private_subnets
    security_groups      = var.cluster_security_groups
    execution_role_arn   = var.cluster_execution_role_arn
  }

  task = [{
    name      = var.name
    image     = "${local.ecr_repo}/${var.name}:${var.label}"
    cpu       = var.cpu
    memory    = var.mem
    command   = var.command
    essential = true
    portMappings = [{
      hostPort      = var.target_port
      containerPort = var.target_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-create-group  = "true"
        awslogs-region        = var.region
        awslogs-group         = var.project_owner
        awslogs-stream-prefix = var.prefix
      }
    }
  }]
}

resource "aws_iam_role" "ecs" {
  name = "${var.name}-role"
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

resource "aws_iam_role_policy_attachment" "ecs" {
  count = length(local.policies)
  role  = aws_iam_role.ecs.name
  policy_arn = local.policies[count.index]
}

module "ecs" {
  source = "github.com/aplaceformom/terraform-ecs-app"

  name    = var.name
  prefix  = var.prefix != "" ? var.prefix : "ecs"
  family  = var.project_name
  image   = "${local.ecr_repo}/${var.name}:${var.label}"
  memory  = var.mem
  cpus    = var.cpu
  public  = var.public
  cluster = local.cluster

  task_role_arn = aws_iam_role.ecs.arn

  enable_autoscaling             = var.autoscaling
  desired_count                  = var.autoscaling_min
  autoscaling_min_count          = var.autoscaling_min
  autoscaling_max_count          = var.autoscaling_max
  autoscaling_scale_out_cooldown = var.autoscaling_cooldown

  port        = var.target_port
  tg_protocol = var.target_protocol

  lb_port     = var.listener_port
  lb_protocol = var.listener_protocol
  certificate = var.certificate ? aws_acm_certificate.cert[0].arn : ""

  health_check_port         = var.target_port
  health_check_path         = var.health_check_path
  health_check_timeout      = var.health_check_timeout
  health_check_interval     = var.health_check_interval
  health_check_grace_period = var.health_check_grace_period

  security_group_ids = [aws_security_group.self.id]

  template = tostring(jsonencode(local.task))
}
