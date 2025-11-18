packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_name_prefix" {
  type    = string
  default = "ubuntu-hardened-ecoutu"
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKv8m3jUvYaWiAJOCMLudYmZ6ig3ZVY/SfWo7PyAUdNZgZ9wO9NGAyjph66BRg1mlsXFfJF+9u1+P2hS2wZeZjzwSKIupdU8IkBwg+37nFe/lZwb6HJyRiz1Ll7diPIXOZ684t7o+sa6Sl4hqVt2xK7EdAGjMOn2cj1v5OKAaHj8zVHCQSLMbmFOONbYD+cyNz49pVVKnCYcdNjWJ2DtquKLDetUt1h69prd4h+xi4uXlaL/mV4nzjeONR6LkYzBFa/Bf454meGNJUavZNDPZ5jtxpkLy8eUzDo9i862P7oZRjEnHxOggG3NbbOVJpBZS4qFWAah+Djgw4MD7Lblzp1ltyb0xGOojHOo1pA9aLwjXcXmYNIy3Bmpa/qWARTJmUTbLTb/7HW1Kpd75Uc7TmUj9dwk54WgNXc9oEnR7RaJLr9jmtvss0FMB5ZyQfg+PyBwy1D3RzFBM4v40hZW0WBves23oXZLAn3BxifMpn14z/wLHGY4NHDYWGAbFGKXEBkAlobV//6JD6gecCQisrLajIKQNepkPk+jAc6zHBOiQZx3j2/jrm1IEnEO4RN48Px7Xa3dLDZn+m/3fEWoQKCkdwD4ymzXNBdsPCI26DSH/5cs7SEeQjTbtAz03KdsYsTfNKAZiH34kkvpNM03MaZLb2mWD9lukr3VJtmHk5vQ=="
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name_prefix}-${local.timestamp}"
  instance_type = var.instance_type
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }

  ssh_username = "ubuntu"

  tags = {
    Name         = "${var.ami_name_prefix}-${local.timestamp}"
    OS           = "Ubuntu"
    OS_Version   = "24.04"
    Created_By   = "Packer"
    Created_Date = local.timestamp
  }
}

build {
  name    = "ubuntu-hardened"
  sources = ["source.amazon-ebs.ubuntu"]

  # Update system packages
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Updating package lists...'",
      "sudo apt-get update",
      "echo 'Upgrading packages...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "echo 'Installing security updates...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y"
    ]
  }

  # Install essential packages
  provisioner "shell" {
    inline = [
      "echo 'Installing essential packages...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \\",
      "  fail2ban \\",
      "  ufw \\",
      "  unattended-upgrades \\",
      "  apt-listchanges \\",
      "  needrestart \\",
      "  curl \\",
      "  wget \\",
      "  git \\",
      "  vim \\",
      "  htop \\",
      "  net-tools \\",
      "  jq"
    ]
  }

  # Create ecoutu user and setup SSH
  provisioner "shell" {
    inline = [
      "echo 'Creating ecoutu user...'",
      "sudo useradd -m -s /bin/bash -G sudo ecoutu",
      "echo 'ecoutu ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ecoutu",
      "sudo chmod 0440 /etc/sudoers.d/ecoutu",
      "echo 'Setting up SSH for ecoutu user...'",
      "sudo mkdir -p /home/ecoutu/.ssh",
      "echo '${var.ssh_public_key}' | sudo tee /home/ecoutu/.ssh/authorized_keys",
      "sudo chmod 700 /home/ecoutu/.ssh",
      "sudo chmod 600 /home/ecoutu/.ssh/authorized_keys",
      "sudo chown -R ecoutu:ecoutu /home/ecoutu/.ssh"
    ]
  }

  # Harden SSH configuration
  provisioner "shell" {
    inline = [
      "echo 'Hardening SSH configuration...'",
      "sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup",
      "sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#MaxSessions 10/MaxSessions 2/' /etc/ssh/sshd_config",
      "echo 'AllowUsers ecoutu' | sudo tee -a /etc/ssh/sshd_config",
      "echo 'Protocol 2' | sudo tee -a /etc/ssh/sshd_config",
      "sudo sshd -t" # Test SSH config
    ]
  }

  # Configure firewall (UFW)
  provisioner "shell" {
    inline = [
      "echo 'Configuring UFW firewall...'",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow 22/tcp comment 'SSH'",
      "sudo ufw --force enable",
      "sudo ufw status"
    ]
  }

  # Configure fail2ban
  provisioner "shell" {
    inline = [
      "echo 'Configuring fail2ban...'",
      "sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'",
      "[DEFAULT]",
      "bantime = 3600",
      "findtime = 600",
      "maxretry = 3",
      "",
      "[sshd]",
      "enabled = true",
      "port = ssh",
      "filter = sshd",
      "logpath = /var/log/auth.log",
      "maxretry = 3",
      "EOF",
      "sudo systemctl enable fail2ban",
      "sudo systemctl restart fail2ban"
    ]
  }

  # Configure automatic security updates
  provisioner "shell" {
    inline = [
      "echo 'Configuring automatic security updates...'",
      "sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<'EOF'",
      "Unattended-Upgrade::Allowed-Origins {",
      "    \"$${distro_id}:$${distro_codename}\";",
      "    \"$${distro_id}:$${distro_codename}-security\";",
      "    \"$${distro_id}ESMApps:$${distro_codename}-apps-security\";",
      "    \"$${distro_id}ESM:$${distro_codename}-infra-security\";",
      "};",
      "Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";",
      "Unattended-Upgrade::MinimalSteps \"true\";",
      "Unattended-Upgrade::Remove-Unused-Kernel-Packages \"true\";",
      "Unattended-Upgrade::Remove-Unused-Dependencies \"true\";",
      "Unattended-Upgrade::Automatic-Reboot \"false\";",
      "EOF",
      "sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'",
      "APT::Periodic::Update-Package-Lists \"1\";",
      "APT::Periodic::Unattended-Upgrade \"1\";",
      "APT::Periodic::AutocleanInterval \"7\";",
      "EOF"
    ]
  }

  # System hardening - kernel parameters
  provisioner "shell" {
    inline = [
      "echo 'Applying kernel security parameters...'",
      "sudo tee -a /etc/sysctl.conf > /dev/null <<'EOF'",
      "",
      "# IP Spoofing protection",
      "net.ipv4.conf.all.rp_filter = 1",
      "net.ipv4.conf.default.rp_filter = 1",
      "",
      "# Ignore ICMP redirects",
      "net.ipv4.conf.all.accept_redirects = 0",
      "net.ipv6.conf.all.accept_redirects = 0",
      "net.ipv4.conf.all.send_redirects = 0",
      "",
      "# Ignore source packet routing",
      "net.ipv4.conf.all.accept_source_route = 0",
      "net.ipv6.conf.all.accept_source_route = 0",
      "",
      "# Ignore ICMP ping requests",
      "net.ipv4.icmp_echo_ignore_all = 0",
      "",
      "# Disable IPv6 if not needed",
      "# net.ipv6.conf.all.disable_ipv6 = 1",
      "# net.ipv6.conf.default.disable_ipv6 = 1",
      "",
      "# Enable TCP SYN Cookie Protection",
      "net.ipv4.tcp_syncookies = 1",
      "",
      "# Log Martians",
      "net.ipv4.conf.all.log_martians = 1",
      "EOF",
      "sudo sysctl -p"
    ]
  }

  # Disable root login
  provisioner "shell" {
    inline = [
      "echo 'Disabling root password...'",
      "sudo passwd -l root"
    ]
  }

  # Remove ubuntu user
  provisioner "shell" {
    inline = [
      "echo 'Preparing to remove ubuntu user...'",
      "# The ubuntu user will be removed on first boot via cloud-init",
      "sudo tee /var/lib/cloud/scripts/per-once/remove-ubuntu-user.sh > /dev/null <<'EOF'",
      "#!/bin/bash",
      "# Remove ubuntu user after first boot",
      "if id ubuntu &>/dev/null; then",
      "    userdel -r ubuntu 2>/dev/null || true",
      "    echo 'Ubuntu user removed successfully'",
      "fi",
      "EOF",
      "sudo chmod +x /var/lib/cloud/scripts/per-once/remove-ubuntu-user.sh"
    ]
  }

  # Set up cloud-init for ecoutu user
  provisioner "shell" {
    inline = [
      "echo 'Configuring cloud-init for ecoutu user...'",
      "sudo tee /etc/cloud/cloud.cfg.d/99_custom_user.cfg > /dev/null <<'EOF'",
      "system_info:",
      "  default_user:",
      "    name: ecoutu",
      "    sudo: ALL=(ALL) NOPASSWD:ALL",
      "    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]",
      "    shell: /bin/bash",
      "EOF"
    ]
  }

  # Install Docker
  provisioner "shell" {
    inline = [
      "echo 'Installing Docker...'",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \\",
      "  ca-certificates \\",
      "  curl \\",
      "  gnupg \\",
      "  lsb-release",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ecoutu",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "docker --version"
    ]
  }

  # Install kubectl
  provisioner "shell" {
    inline = [
      "echo 'Installing kubectl...'",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256\"",
      "echo \"$(cat kubectl.sha256)  kubectl\" | sha256sum --check",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "rm kubectl kubectl.sha256",
      "kubectl version --client"
    ]
  }

  # Install minikube
  provisioner "shell" {
    inline = [
      "echo 'Installing minikube...'",
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "rm minikube-linux-amd64",
      "minikube version",
      "echo 'Configuring minikube autostart...'",
      "sudo tee /etc/systemd/system/minikube.service > /dev/null <<'EOF'",
      "[Unit]",
      "Description=Minikube Kubernetes Cluster",
      "After=docker.service",
      "Requires=docker.service",
      "",
      "[Service]",
      "Type=oneshot",
      "RemainAfterExit=yes",
      "User=ecoutu",
      "Group=ecoutu",
      "ExecStart=/usr/local/bin/minikube start --driver=docker --listen-address=0.0.0.0 --apiserver-ips=127.0.0.1",
      "ExecStop=/usr/local/bin/minikube stop",
      "StandardOutput=journal",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo systemctl daemon-reload",
      "echo 'Minikube service configured (will start on first boot)'"
    ]
  }

  # Install helm
  provisioner "shell" {
    inline = [
      "echo 'Installing Helm...'",
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "helm version"
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "sudo rm -f /root/.bash_history",
      "sudo rm -f /home/ubuntu/.bash_history 2>/dev/null || true",
      "sudo rm -f /home/ecoutu/.bash_history 2>/dev/null || true",
      "sudo find /var/log -type f -exec truncate -s 0 {} \\;",
      "echo 'AMI preparation complete!'"
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
