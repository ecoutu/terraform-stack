# EC2 Instance Module

A reusable Terraform module for creating EC2 instances with customizable security groups, AMI selection, and networking configuration.

## Features

- **Flexible AMI Selection**: Use specific AMI ID or automatic lookup with filters
- **Customizable Security Groups**: Define ingress/egress rules as needed
- **Configurable Networking**: Public/private IP, subnet placement
- **Optional SSH Key**: Attach SSH key pairs for access
- **User Data Support**: Run initialization scripts on launch
- **Block Device Configuration**: Customize root volume size and type
- **Detailed Monitoring**: Optional CloudWatch detailed monitoring
- **Tagging Support**: Apply custom tags to all resources

## Usage

### Basic Example

```hcl
module "web_server" {
  source = "./modules/ec2-instance"

  name_prefix   = "my-web-server"
  subnet_ids    = ["subnet-abc123"]
  vpc_id        = "vpc-xyz789"
  instance_type = "t3.small"

  security_group_ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  tags = {
    Environment = "production"
    Application = "web"
  }
}
```

### With Specific AMI

```hcl
module "instance" {
  source = "./modules/ec2-instance"

  name_prefix = "custom-ami-instance"
  subnet_ids  = module.vpc.public_subnet_ids
  vpc_id      = module.vpc.vpc_id
  ami_id      = "ami-0c55b159cbfafe1f0"

  security_group_ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

### With User Data

```hcl
module "instance" {
  source = "./modules/ec2-instance"

  name_prefix   = "bootstrapped-instance"
  subnet_ids    = module.vpc.public_subnet_ids
  vpc_id        = module.vpc.vpc_id
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
  EOF

  security_group_ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Prefix for resource names | `string` | n/a | yes |
| `subnet_ids` | List of subnet IDs (first will be used) | `list(string)` | n/a | yes |
| `vpc_id` | VPC ID for security group | `string` | n/a | yes |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `ami_id` | Specific AMI ID (overrides filter) | `string` | `null` | no |
| `ami_name_filter` | AMI name filter pattern | `string` | `"ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64*"` | no |
| `ami_owner` | AMI owner ID | `string` | `"099720109477"` | no |
| `security_group_ingress_rules` | List of ingress rules | `list(object)` | `[]` | no |
| `security_group_egress_rules` | List of egress rules | `list(object)` | Allow all | no |
| `key_name` | SSH key pair name | `string` | `null` | no |
| `user_data` | User data script | `string` | `null` | no |
| `associate_public_ip_address` | Associate public IP | `bool` | `true` | no |
| `root_block_device_volume_size` | Root volume size (GB) | `number` | `32` | no |
| `root_block_device_volume_type` | Root volume type | `string` | `"gp3"` | no |
| `enable_monitoring` | Enable detailed monitoring | `bool` | `false` | no |
| `tags` | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP address |
| `private_ip` | Private IP address |
| `public_dns` | Public DNS name |
| `private_dns` | Private DNS name |
| `security_group_id` | Security group ID |
| `ami_id` | AMI ID used |

## Notes

- The module places the instance in the first subnet from `subnet_ids`
- Default egress rule allows all outbound traffic
- Default AMI is Ubuntu 22.04 LTS from Canonical
- Security group is created and managed by the module
- For production use, restrict security group rules to specific CIDRs
