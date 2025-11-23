data "aws_ami" "selected" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.selected[0].id
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-sg-"
  description = "Security group for ${var.name_prefix}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      description = try(ingress.value.description, null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      description = try(egress.value.description, null)
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg"
    }
  )
}

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = element(var.subnet_ids, 0)
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = var.key_name
  user_data                   = var.user_data
  associate_public_ip_address = var.associate_public_ip_address
  monitoring                  = var.enable_monitoring
  iam_instance_profile        = var.iam_instance_profile

  root_block_device {
    volume_size = var.root_block_device_volume_size
    volume_type = var.root_block_device_volume_type
  }

  tags = merge(
    var.tags,
    {
      Name = var.name_prefix
    }
  )
}
