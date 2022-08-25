
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/${var.component}/${var.deployment_identifier}/ecs-cluster/${var.cluster_name}"
  retention_in_days = var.cw_log_retention_in_days
}
