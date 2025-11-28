# IAM Role Module - Main Resources

# IAM Role
resource "aws_iam_role" "this" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = var.custom_assume_role_policy != null ? var.custom_assume_role_policy : data.aws_iam_policy_document.assume_role[0].json
  path               = var.role_path

  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies


  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# Inline policies (use aws_iam_role_policy instead of deprecated inline_policy block)
resource "aws_iam_role_policy" "inline" {
  for_each = { for p in var.inline_policies : p.name => p }

  name   = each.value.name
  role   = aws_iam_role.this.id
  policy = each.value.policy
}

# Assume Role Policy Document (if custom policy not provided)
data "aws_iam_policy_document" "assume_role" {
  count = var.custom_assume_role_policy == null ? 1 : 0

  # Statement for AWS Services (no MFA required for services)
  dynamic "statement" {
    for_each = length(var.trusted_services) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  # Statement for IAM users/roles (MFA can be required)
  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }

      # Add MFA condition if required
      dynamic "condition" {
        for_each = var.require_mfa ? [1] : []
        content {
          test     = "Bool"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["true"]
        }
      }

      # Add any additional custom conditions
      dynamic "condition" {
        for_each = var.assume_role_conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Create and attach custom policies
resource "aws_iam_policy" "custom" {
  for_each = var.custom_policies

  name        = each.value.name
  description = each.value.description
  policy      = each.value.policy
  path        = var.policy_path

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}

resource "aws_iam_role_policy_attachment" "custom_policies" {
  for_each = aws_iam_policy.custom

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

# Instance Profile (for EC2)
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.instance_profile_name != null ? var.instance_profile_name : var.role_name
  role = aws_iam_role.this.name
  path = var.role_path

  tags = merge(
    var.tags,
    {
      Name = var.instance_profile_name != null ? var.instance_profile_name : var.role_name
    }
  )
}
