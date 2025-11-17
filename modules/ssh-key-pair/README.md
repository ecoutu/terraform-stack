# SSH Key Pair Module

A simple Terraform module for creating AWS EC2 key pairs from SSH public keys.

## Features

- Creates AWS EC2 key pair from SSH public key material
- Supports custom tagging
- Outputs key name, ID, and fingerprint

## Usage

### Basic Example

```hcl
module "ssh_key" {
  source = "./modules/ssh-key-pair"

  key_name   = "my-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Environment = "production"
    Owner       = "ops-team"
  }
}
```

### With Inline Public Key

```hcl
module "ssh_key" {
  source = "./modules/ssh-key-pair"

  key_name   = "deployment-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."

  tags = {
    Purpose = "CI/CD Deployments"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `key_name` | Name of the SSH key pair | `string` | n/a | yes |
| `public_key` | SSH public key material | `string` | n/a | yes |
| `tags` | Additional tags for the key pair | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `key_name` | Name of the SSH key pair |
| `key_pair_id` | ID of the SSH key pair |
| `fingerprint` | Fingerprint of the SSH key pair |

## Notes

- The key pair name must be unique within the AWS region
- Public key must be in OpenSSH format
- Maximum key pair name length is 255 characters
- AWS supports RSA, ED25519, and ECDSA keys
