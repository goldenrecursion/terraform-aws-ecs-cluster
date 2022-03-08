resource "aws_iam_role" "cluster_instance_role" {
  description        = "cluster-instance-role-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  assume_role_policy = file("${path.module}/policies/cluster-instance-role.json")

  tags = local.tags
}

data "template_file" "cluster_instance_policy" {
  template = file("${path.module}/policies/cluster-instance-policy.json")
}

resource "aws_iam_policy" "cluster_instance_policy" {
  description = "cluster-instance-policy-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  policy      = coalesce(var.cluster_instance_iam_policy_contents, data.template_file.cluster_instance_policy.rendered)
}

resource "aws_iam_policy_attachment" "cluster_instance_policy_attachment" {
  name       = "cluster-instance-policy-attachment-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  roles      = [aws_iam_role.cluster_instance_role.id]
  policy_arn = aws_iam_policy.cluster_instance_policy.arn
}

resource "aws_iam_instance_profile" "cluster" {
  name = "cluster-instance-profile-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  path = "/"
  role = aws_iam_role.cluster_instance_role.name
}

resource "aws_iam_role" "cluster_service_role" {
  description        = "cluster-service-role-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  assume_role_policy = file("${path.module}/policies/cluster-service-role.json")

  tags = local.tags
}

resource "aws_iam_policy" "cluster_service_policy" {
  description = "cluster-service-policy-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  policy      = coalesce(var.cluster_service_iam_policy_contents, file("${path.module}/policies/cluster-service-policy.json"))
}

resource "aws_iam_policy_attachment" "cluster_service_policy_attachment" {
  name       = "cluster-instance-policy-attachment-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  roles      = [aws_iam_role.cluster_service_role.id]
  policy_arn = aws_iam_policy.cluster_service_policy.arn
}

resource "aws_iam_role" "task_execution_role" {
  name               = "cluster-task-execution-role-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role.json
}

data "aws_iam_policy_document" "task_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_role" {
  name   = "cluster-task-execution-policy-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  policy = data.aws_iam_policy_document.task_execution_role.json
  role   = aws_iam_role.task_execution_role.id
}



resource "null_resource" "iam_wait" {
  depends_on = [
    aws_iam_role.cluster_instance_role,
    aws_iam_policy.cluster_instance_policy,
    aws_iam_policy_attachment.cluster_instance_policy_attachment,
    aws_iam_instance_profile.cluster,
    aws_iam_role.cluster_service_role,
    aws_iam_policy.cluster_service_policy,
    aws_iam_policy_attachment.cluster_service_policy_attachment,
    aws_iam_role.task_execution_role,
    aws_iam_role_policy.task_execution_role,
  ]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
