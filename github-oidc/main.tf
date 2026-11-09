data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  github_sub = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

# ---------------------------------------------------------------- OIDC provider

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

# ------------------------------------------------------------------- deploy role

# Trust policy: only workflow runs from this repository and branch can assume the role.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "${var.project_name}-github-deploy"
  description          = "Assumed by GitHub Actions (OIDC) to push to ECR and deploy to ECS"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

# Permissions: push images to one ECR repository and update one ECS service.
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action does not support resource-level limits
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:DescribeImages",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}"]
  }

  statement {
    sid       = "EcsTaskDefinitions"
    actions   = ["ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition"]
    resources = ["*"] # these two actions do not support resource-level limits
  }

  statement {
    sid     = "EcsService"
    actions = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${local.account_id}:service/${var.project_name}-cluster/${var.project_name}-service",
    ]
  }

  # A new task definition revision names the two roles the task uses.
  statement {
    sid     = "PassTaskRoles"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.project_name}-execution-role",
      "arn:aws:iam::${local.account_id}:role/${var.project_name}-task-role",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "ecr-push-and-ecs-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
