# Packer AMI Builder

This directory contains Packer templates for building hardened Ubuntu AMIs.

## Overview

The `ubuntu-hardened.pkr.hcl` template creates a security-hardened Ubuntu 22.04 AMI with:

- **Custom User**: Creates `ecoutu` user with sudo access
- **SSH Hardening**: Disables password auth, root login, configures secure defaults
- **Firewall**: UFW configured with default deny incoming
- **Intrusion Prevention**: fail2ban configured for SSH protection
- **Automatic Updates**: Unattended security updates enabled
- **Kernel Hardening**: Sysctl parameters for network security
- **Clean State**: Removes default ubuntu user on first boot

## Prerequisites

1. **Install Packer**
   ```bash
   # macOS
   brew install packer

   # Linux
   wget https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_linux_amd64.zip
   unzip packer_1.10.0_linux_amd64.zip
   sudo mv packer /usr/local/bin/
   ```

2. **AWS Credentials**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"

   # Or use AWS CLI configuration
   aws configure
   ```

3. **Required IAM Permissions**
   - ec2:AttachVolume
   - ec2:AuthorizeSecurityGroupIngress
   - ec2:CopyImage
   - ec2:CreateImage
   - ec2:CreateKeypair
   - ec2:CreateSecurityGroup
   - ec2:CreateSnapshot
   - ec2:CreateTags
   - ec2:CreateVolume
   - ec2:DeleteKeypair
   - ec2:DeleteSecurityGroup
   - ec2:DeleteSnapshot
   - ec2:DeleteVolume
   - ec2:DeregisterImage
   - ec2:DescribeImageAttribute
   - ec2:DescribeImages
   - ec2:DescribeInstances
   - ec2:DescribeRegions
   - ec2:DescribeSecurityGroups
   - ec2:DescribeSnapshots
   - ec2:DescribeSubnets
   - ec2:DescribeTags
   - ec2:DescribeVolumes
   - ec2:DetachVolume
   - ec2:GetPasswordData
   - ec2:ModifyImageAttribute
   - ec2:ModifyInstanceAttribute
   - ec2:ModifySnapshotAttribute
   - ec2:RegisterImage
   - ec2:RunInstances
   - ec2:StopInstances
   - ec2:TerminateInstances

## Usage

### Build AMI

```bash
cd packer

# Validate template
packer validate ubuntu-hardened.pkr.hcl

# Build AMI
packer build ubuntu-hardened.pkr.hcl
```

### Build with Custom Variables

```bash
packer build \
  -var 'aws_region=us-west-2' \
  -var 'instance_type=t3.medium' \
  -var 'ami_name_prefix=my-custom-ami' \
  ubuntu-hardened.pkr.hcl
```

### Build with Variable File

Create `variables.pkrvars.hcl`:

```hcl
aws_region      = "us-east-1"
instance_type   = "t3.small"
ami_name_prefix = "prod-ubuntu-hardened"
ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2E..."
```

Build with variables:

```bash
packer build -var-file=variables.pkrvars.hcl ubuntu-hardened.pkr.hcl
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to build in | `us-east-1` |
| `instance_type` | EC2 instance type for build | `t3.small` |
| `ami_name_prefix` | Prefix for AMI name | `ubuntu-hardened-ecoutu` |
| `ssh_public_key` | SSH public key for ecoutu user | (provided in template) |

## Security Features

### SSH Hardening
- ✅ Password authentication disabled
- ✅ Root login disabled
- ✅ Public key authentication only
- ✅ Max auth tries: 3
- ✅ Client alive interval: 300s
- ✅ Only `ecoutu` user allowed
- ✅ Protocol 2 only

### Firewall Configuration
- ✅ UFW enabled
- ✅ Default deny incoming
- ✅ Default allow outgoing
- ✅ SSH (22) allowed

### Intrusion Detection
- ✅ fail2ban configured
- ✅ 3 hour ban after 3 failed attempts
- ✅ SSH jail enabled

### System Hardening
- ✅ IP spoofing protection
- ✅ ICMP redirect ignore
- ✅ Source routing disabled
- ✅ TCP SYN cookies enabled
- ✅ Martian packet logging

### Automatic Updates
- ✅ Security updates auto-installed
- ✅ Kernel packages auto-removed
- ✅ Dependencies auto-cleaned

## Using the AMI in Terraform

After building, get the AMI ID from the output or `packer-manifest.json`:

```bash
# Get AMI ID from manifest
AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d':' -f2)
echo $AMI_ID
```

Update your EC2 instance module:

```hcl
module "minikube" {
  source = "./modules/ec2-instance"

  ami_id        = "ami-xxxxxxxxxxxxx"  # Your Packer-built AMI
  instance_type = "t3.small"
  name_prefix   = "minikube"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  key_name      = module.ssh_key.key_name

  # ... rest of configuration
}
```

Or use data source to find latest:

```hcl
data "aws_ami" "hardened_ubuntu" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["ubuntu-hardened-ecoutu-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

module "minikube" {
  source = "./modules/ec2-instance"

  ami_id = data.aws_ami.hardened_ubuntu.id
  # ... rest of configuration
}
```

## Troubleshooting

### Build Fails at SSH Step
- Check security group allows SSH (port 22)
- Verify AWS credentials have necessary permissions
- Ensure source AMI is available in your region

### "No valid credential sources found"
```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Or configure AWS CLI
aws configure
```

### AMI Not Found
```bash
# List available Ubuntu AMIs
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[*].[Name,ImageId]' \
  --output table
```

## Post-Build Testing

### Test SSH Access

```bash
# Get AMI ID
AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d':' -f2)

# Launch test instance
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name your-key-pair \
  --security-group-ids sg-xxxxx \
  --subnet-id subnet-xxxxx

# SSH as ecoutu user
ssh -i ~/.ssh/id_rsa ecoutu@<instance-ip>
```

### Verify Security Settings

```bash
# Check SSH config
ssh ecoutu@<instance-ip> 'sudo sshd -T | grep -E "passwordauth|pubkey|rootlogin"'

# Check firewall
ssh ecoutu@<instance-ip> 'sudo ufw status'

# Check fail2ban
ssh ecoutu@<instance-ip> 'sudo fail2ban-client status sshd'

# Verify ubuntu user is removed
ssh ecoutu@<instance-ip> 'id ubuntu 2>&1'
# Should return: id: 'ubuntu': no such user
```

## Maintenance

### Update Base AMI
The template automatically uses the latest Ubuntu 22.04 AMI from Canonical. Rebuild regularly to get latest security patches.

### Update SSH Key
Edit the `ssh_public_key` variable or pass via `-var` flag:

```bash
packer build \
  -var "ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  ubuntu-hardened.pkr.hcl
```

### Customize Hardening
Edit the provisioner shell blocks in `ubuntu-hardened.pkr.hcl` to add or modify security settings.

## References

- [Packer Documentation](https://www.packer.io/docs)
- [AWS EC2 AMI Builder](https://www.packer.io/plugins/builders/amazon/ebs)
- [Ubuntu Security Features](https://ubuntu.com/security)
- [CIS Ubuntu Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)
