resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { 
      type = "Federated" 
      identifiers = [aws_iam_openid_connect_provider.github.arn] 
      }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main", "repo:${var.github_repo}:pull_request"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_policy" "deploy_policy" {
  name   = "${var.name}-deploy-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Sid = "ECR", Effect = "Allow", Action = [
          "ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart","ecr:InitiateLayerUpload","ecr:PutImage","ecr:BatchGetImage","ecr:DescribeRepositories"
        ], Resource = "*" },
      { Sid = "ECS", Effect = "Allow", Action = [
          "ecs:DescribeClusters","ecs:DescribeServices","ecs:RegisterTaskDefinition","ecs:DescribeTaskDefinition",
          "ecs:UpdateService","ecs:CreateService","ecs:DeleteService","ecs:ListTaskDefinitions"
        ], Resource = "*" },
      { Sid = "IAMPass", Effect = "Allow", Action = ["iam:PassRole"], Resource = "*" },
      { Sid = "ALB", Effect = "Allow", Action = ["elasticloadbalancing:*"], Resource = "*" },
      { Sid = "CodeDeploy", Effect = "Allow", Action = ["codedeploy:*"], Resource = "*" },
      { Sid = "CW", Effect = "Allow", Action = ["logs:*","cloudwatch:*"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.deploy.name
  policy_arn = aws_iam_policy.deploy_policy.arn
}


