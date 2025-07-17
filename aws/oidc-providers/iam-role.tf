# # IAM Policy for EC2 management
# resource "aws_iam_policy" "github_actions_ec2_policy" {
#   name        = "${var.project_name}-github-actions-ec2-policy"
#   description = "Policy for GitHub Actions to manage EC2 resources"
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # EC2 Instance Management
#           "ec2:RunInstances",
#           "ec2:TerminateInstances",
#           "ec2:StartInstances",
#           "ec2:StopInstances",
#           "ec2:RebootInstances",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceStatus",
#           "ec2:DescribeInstanceAttribute",
#           "ec2:ModifyInstanceAttribute",
#
#           # AMI Management
#           "ec2:CreateImage",
#           "ec2:DeregisterImage",
#           "ec2:DescribeImages",
#           "ec2:ModifyImageAttribute",
#           "ec2:CopyImage",
#
#           # Snapshot Management
#           "ec2:CreateSnapshot",
#           "ec2:DeleteSnapshot",
#           "ec2:DescribeSnapshots",
#           "ec2:ModifySnapshotAttribute",
#           "ec2:CopySnapshot",
#
#           # Volume Management
#           "ec2:CreateVolume",
#           "ec2:DeleteVolume",
#           "ec2:AttachVolume",
#           "ec2:DetachVolume",
#           "ec2:DescribeVolumes",
#           "ec2:ModifyVolume",
#
#           # Security Groups
#           "ec2:CreateSecurityGroup",
#           "ec2:DeleteSecurityGroup",
#           "ec2:DescribeSecurityGroups",
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:AuthorizeSecurityGroupEgress",
#           "ec2:RevokeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupEgress",
#
#           # Key Pairs
#           "ec2:CreateKeyPair",
#           "ec2:DeleteKeyPair",
#           "ec2:DescribeKeyPairs",
#           "ec2:ImportKeyPair",
#
#           # VPC and Networking
#           "ec2:DescribeVpcs",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeRouteTables",
#           "ec2:DescribeInternetGateways",
#
#           # Tags
#           "ec2:CreateTags",
#           "ec2:DeleteTags",
#           "ec2:DescribeTags",
#
#           # Launch Templates
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateLaunchTemplateVersion",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeLaunchTemplateVersions",
#           "ec2:ModifyLaunchTemplate",
#
#           # Placement Groups
#           "ec2:CreatePlacementGroup",
#           "ec2:DeletePlacementGroup",
#           "ec2:DescribePlacementGroups"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "ec2:InstanceType" = var.allowed_instance_types
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Additional permissions without instance type restriction
#           "ec2:DescribeRegions",
#           "ec2:DescribeAccountAttributes",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # IAM permissions for instance profiles
#           "iam:PassRole"
#         ]
#         Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ec2-*"
#       }
#     ]
#   })
#
#   # tags = local.common_tags
# }


# Additional IAM Policy specifically for ec2-github-runner action
resource "aws_iam_policy" "github_runner_policy" {
  name        = "${var.project_name}-github-runner-policy"
  description = "Additional policy for machulav/ec2-github-runner action"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Core permissions required by ec2-github-runner
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances", 
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        # For IAM role attachment to EC2 instances
        Effect = "Allow"
        Action = [
          "ec2:ReplaceIamInstanceProfileAssociation",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile"
        ]
        Resource = "*"
      },
      {
        # For passing IAM roles to EC2 instances
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        # For creating tags on EC2 instances and volumes
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      },
      {
        # For Spot instances - service-linked role creation
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "spot.amazonaws.com"
          }
        }
      },
      {
        # For Spot instance requests
        Effect = "Allow"
        Action = [
          "ec2:RequestSpotInstances",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:CancelSpotInstanceRequests",
          "ec2:DescribeSpotPriceHistory"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.github_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = var.tags
}

# # Attach policies to role
# resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
#   role       = aws_iam_role.github_actions_role.name
#   policy_arn = aws_iam_policy.github_actions_ec2_policy.arn
# }

resource "aws_iam_role_policy_attachment" "github_runner_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_runner_policy.arn
}

# EC2 Instance Role (for instances created by GitHub Actions)
resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.project_name}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# EC2 Instance Profile
# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "${var.project_name}-ec2-instance-profile"
#   role = aws_iam_role.ec2_instance_role.name
#
#   tags = local.common_tags
# }
#
# # Basic policy for EC2 instances (customize as needed)
# resource "aws_iam_policy" "ec2_instance_policy" {
#   name        = "${var.project_name}-ec2-instance-policy"
#   description = "Basic policy for EC2 instances"
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeTags",
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
#
#   tags = var.tags
# }
#
# resource "aws_iam_role_policy_attachment" "ec2_instance_policy_attachment" {
#   role       = aws_iam_role.ec2_instance_role.name
#   policy_arn = aws_iam_policy.ec2_instance_policy.arn
# }
#
# # Attach AWS managed policy for SSM
# resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_policy" {
#   role       = aws_iam_role.ec2_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }
