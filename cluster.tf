locals {
  cluster_full_name = "${var.component}-${var.deployment_identifier}-${var.cluster_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_full_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights == "yes" ? "enabled" : "disabled"
  }

  tags = local.tags

  depends_on = [
    null_resource.iam_wait
  ]
}

resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  cluster_name       = local.cluster_full_name
  capacity_providers = var.include_asg_capacity_provider == "yes" ? [aws_ecs_capacity_provider.autoscaling_group[0].name] : []
}