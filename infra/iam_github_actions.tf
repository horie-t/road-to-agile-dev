###############################################
# GitHub Actions OIDC Provider and IAM Role
###############################################

locals {
  github_oidc_thumbprints = [
    # Current GitHub OIDC root CAs (as of 2023+). Keep both for safety.
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.github_oidc_thumbprints
  tags            = local.tags
}

data "aws_iam_policy_document" "gha_assume_role" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to configured repos/refs
    dynamic "condition" {
      for_each = length(var.github_oidc_subjects) > 0 ? [1] : []
      content {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = var.github_oidc_subjects
      }
    }
  }
}

resource "aws_iam_role" "gha_push_ecr" {
  count = var.enable_github_oidc ? 1 : 0

  name               = "${local.name_prefix}-gha-ecr-push-role"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role[0].json
  description        = "Role assumed by GitHub Actions via OIDC to push images to ECR"
  tags               = local.tags
}

data "aws_iam_policy_document" "gha_ecr_push" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid     = "EcrAuthToken"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrRepositoryActions"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [
      aws_ecr_repository.app.arn,
      aws_ecr_repository.frontend.arn
    ]
  }
}

resource "aws_iam_policy" "gha_ecr_push" {
  count       = var.enable_github_oidc ? 1 : 0
  name        = "${local.name_prefix}-gha-ecr-push-policy"
  description = "Permissions for GitHub Actions to push Docker images to the project's ECR repository"
  policy      = data.aws_iam_policy_document.gha_ecr_push[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "gha_ecr_push_attach" {
  count      = var.enable_github_oidc ? 1 : 0
  role       = aws_iam_role.gha_push_ecr[0].name
  policy_arn = aws_iam_policy.gha_ecr_push[0].arn
}

output "github_actions_role_arn" {
  value       = var.enable_github_oidc ? aws_iam_role.gha_push_ecr[0].arn : null
  description = "IAM Role ARN for GitHub Actions to assume via OIDC to push images to ECR"
}