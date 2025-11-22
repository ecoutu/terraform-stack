# Main Terraform configuration file

terraform {
  required_version = ">= 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.8"
    }
  }

  backend "s3" {
    bucket       = "ecoutu-terraform-stack-state"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "github" {
  token = var.github_token
}

# Terraform Backend Resources
# Creates S3 bucket and DynamoDB table for remote state
module "terraform_backend" {
  source = "./modules/terraform-backend"
  count  = var.enable_remote_state ? 1 : 0

  bucket_name         = var.terraform_state_bucket
  dynamodb_table_name = "${var.terraform_state_bucket}-lock"
  enable_versioning   = true
  enable_encryption   = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Terraform State Backend"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name     = var.environment
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  enable_nat_gateway      = var.enable_nat_gateway
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSH Key Pair for EC2 Instances
module "ssh_key" {
  source = "./modules/ssh-key-pair"

  key_name   = "${var.environment}-ecoutu-key"
  public_key = var.ssh_public_key

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "SSH access to development instances"
  }
}

# Packer-built Minikube AMI
data "aws_ami" "packer_minikube" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["minikube-ecoutu-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "tag:Created_By"
    values = ["Packer"]
  }
}

# Minikube EC2 instance
module "minikube" {
  source        = "./modules/ec2-instance"
  subnet_ids    = module.vpc.public_subnet_ids
  instance_type = var.minikube_instance_type
  name_prefix   = "${var.environment}-minikube"
  vpc_id        = module.vpc.vpc_id
  key_name      = module.ssh_key.key_name
  ami_id        = data.aws_ami.packer_minikube.id

  # Set hostname to minikube
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname minikube
    echo "127.0.0.1 minikube" >> /etc/hosts
  EOF

  # Minikube-specific security group rules
  security_group_ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr_blocks
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Minikube Development"
  }
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  account_alias   = "ecoutu"
  user_name       = "ecoutu"
  admin_role_name = "${var.environment}-admin-role"

  create_login_profile    = true
  password_reset_required = true
  create_access_key       = true

  admin_role_trusted_services = [
    "ec2.amazonaws.com",
    "lambda.amazonaws.com",
    "ecs-tasks.amazonaws.com"
  ]

  create_instance_profile = true
  max_session_duration    = 43200

  # MFA Settings - Set to false initially to allow user to set up MFA
  # After user has MFA enabled, change these to true and reapply
  require_mfa           = true
  enforce_mfa_for_users = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# GitHub Actions OIDC Role
module "github_actions_role" {
  source = "./modules/github-oidc-role"

  role_name       = "GitHubActionsTerraformRole"
  github_org      = var.github_org
  github_repo     = var.github_repo
  github_branches = var.github_branches

  # Grant Terraform deployment permissions
  inline_policies = {
    TerraformDeployment = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "TerraformStateAccess"
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:GetBucketVersioning"
          ]
          Resource = [
            "arn:aws:s3:::${var.terraform_state_bucket}",
            "arn:aws:s3:::${var.terraform_state_bucket}/*"
          ]
        },
        {
          Sid    = "TerraformStateLocking"
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:DescribeTable"
          ]
          Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.terraform_state_bucket}-lock"
        },
        {
          Sid    = "TerraformResourceManagement"
          Effect = "Allow"
          Action = [
            "ec2:*",
            "vpc:*",
            "iam:*",
            "s3:*",
            "cloudwatch:*",
            "logs:*",
            "dynamodb:*",
            "route53:*"
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "GitHub Actions CI/CD"
  }
}

# GitHub Secrets Configuration
# Automatically sets AWS_ROLE_TO_ASSUME and AWS_REGION in repository
# Also sets all terraform.tfvars variables as GitHub secrets/variables
module "github_secrets" {
  source = "./modules/github-secrets"
  # count  = var.github_token != "" ? 1 : 0

  github_token    = var.github_token
  repository_name = "${var.github_org}/${var.github_repo}"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = var.aws_region

  # Set all terraform.tfvars variables as GitHub secrets/variables
  additional_secrets = merge(
    var.github_secrets,
    {
      # Sensitive values as secrets
      "TF_VAR_github_token" = var.github_token
      "SSH_PUBLIC_KEY"      = var.ssh_public_key
    }
  )

  additional_variables = merge(
    var.github_variables,
    {
      # Non-sensitive values as variables
      "TF_VAR_aws_region"             = var.aws_region
      "TF_VAR_environment"            = var.environment
      "TF_VAR_project_name"           = var.project_name
      "TF_VAR_vpc_cidr"               = var.vpc_cidr
      "TF_VAR_az_count"               = tostring(var.az_count)
      "TF_VAR_enable_nat_gateway"     = tostring(var.enable_nat_gateway)
      "TF_VAR_github_org"             = var.github_org
      "TF_VAR_github_repo"            = var.github_repo
      "TF_VAR_github_branches"        = jsonencode(var.github_branches)
      "TF_VAR_enable_remote_state"    = tostring(var.enable_remote_state)
      "TF_VAR_terraform_state_bucket" = var.terraform_state_bucket
      # Packer variables
      "PKR_VAR_aws_region"      = var.aws_region
      "PKR_VAR_instance_type"   = "t3.small"
      "PKR_VAR_ami_name_prefix" = "minikube-ecoutu"
    }
  )
}

# Route53 Hosted Zones for linklayer.ca
module "route53" {
  source = "./modules/route53"

  domain_name         = var.domain_name
  create_public_zone  = true
  create_private_zone = true
  vpc_id              = module.vpc.vpc_id

  dns_records = {
    minikube_public = {
      name    = "minikube.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = [module.minikube.public_ip]
      zone    = "public"
    }
    minikube_private = {
      name    = "minikube.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = [module.minikube.private_ip]
      zone    = "private"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
