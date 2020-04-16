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
  policy_arn = "arn:aws:iam::${module.shared.account["id"]}:policy/${local.policies[count.index]}"
}

module "ecs" {
  source = "github.com/aplaceformom/terraform-ecs-app"

  name    = var.name
  prefix  = local.ecs["prefix"]
  family  = local.ecs["family"]
  image   = "${local.ecs["image"]}:${var.deploy_id}"
  memory  = var.mem
  cpus    = var.cpu
  public  = var.public
  cluster = module.shared.cluster
  log2elk = false

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
  certificate = module.cert.arn

  health_check_port         = var.target_port
  health_check_path         = var.health_check_path
  health_check_timeout      = var.health_check_timeout
  health_check_interval     = var.health_check_interval
  health_check_grace_period = var.health_check_grace_period

  security_group_ids = [aws_security_group.self.id]

  template = tostring(jsonencode(local.ecs_task))
}
