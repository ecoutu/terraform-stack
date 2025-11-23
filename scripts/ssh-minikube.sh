#!/usr/bin/env bash
#
# SSH into the Minikube EC2 instance with SOCKS proxy for kubectl access
#
# Usage:
#   ./scripts/ssh-minikube.sh                    # SSH with SOCKS proxy
#   ./scripts/ssh-minikube.sh --no-proxy         # SSH without SOCKS proxy
#   ./scripts/ssh-minikube.sh --custom-ports     # SSH with custom port forwarding
#   ./scripts/ssh-minikube.sh --help             # Show help

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
SSH_KEY=""
SSH_USER="ecoutu"
ENABLE_SOCKS_PROXY=true
SOCKS_PORT="${SOCKS_PROXY_PORT:-1080}"

# Default ports to forward
# Format: local_port:remote_port
declare -a DEFAULT_PORTS=(
    "8443:8443"   # Minikube API Server
)

# Additional ports to forward (optional)
# Format: local_port:remote_port
declare -a ADDITIONAL_PORTS=()

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to show usage
show_help() {
    cat << EOF
${GREEN}Minikube SSH Script with SOCKS Proxy${NC}

SSH into the Minikube EC2 instance with SOCKS proxy for remote kubectl management.

${YELLOW}Usage:${NC}
    $0 [OPTIONS]

${YELLOW}Options:${NC}
    --no-proxy          SSH without SOCKS proxy
    --socks-port PORT   SOCKS proxy port (default: 1080)
    --custom-ports      Prompt for additional port forwarding
    --key PATH          Path to SSH private key (optional, uses default SSH config if not specified)
    --user USER         SSH user (default: ecoutu)
    --help              Show this help message

${YELLOW}Default Configuration:${NC}
    SOCKS Proxy:       localhost:1080
    API Server:        localhost:8443 → minikube:8443

${YELLOW}Examples:${NC}
    # SSH with SOCKS proxy on default port
    $0

    # SSH without SOCKS proxy
    $0 --no-proxy

    # SSH with custom SOCKS port
    $0 --socks-port 9999

    # SSH with custom SSH key
    $0 --key ~/.ssh/minikube_rsa

    # SSH with additional port forwarding
    $0 --custom-ports

${YELLOW}Using kubectl with port forwarding:${NC}
    # Configure kubectl to use the forwarded API server
    kubectl config set-cluster minikube-remote \\
        --server=https://localhost:8443 \\
        --insecure-skip-tls-verify=true

    # Or use SOCKS proxy for all traffic
    export HTTPS_PROXY=socks5://localhost:1080

    # Then use kubectl normally
    kubectl get nodes
    kubectl get pods -A

${YELLOW}After connecting:${NC}
    # Check minikube status on remote instance
    minikube status

    # Get minikube IP for kubectl configuration
    minikube ip

    # Access Kubernetes cluster through SOCKS proxy
    # Set HTTPS_PROXY=socks5://localhost:1080 in your local terminal

EOF
}

# Function to get instance IP from Terraform output
get_instance_ip() {
    local ip
    ip=$(cd terraform && terraform output -raw minikube_public_ip 2>/dev/null || echo "")

    if [[ -z "$ip" ]]; then
        print_error "Could not get instance IP from Terraform output"
        print_info "Make sure you have run 'terraform apply' and the minikube instance is running"
        exit 1
    fi

    echo "$ip"
}

# Function to build SSH SOCKS proxy arguments
build_socks_proxy_args() {
    local args=""
    if [[ "$ENABLE_SOCKS_PROXY" == true ]]; then
        args="-D ${SOCKS_PORT}"
    fi
    echo "$args"
}

# Function to get custom ports from user
get_custom_ports() {
    print_info "Enter additional ports to forward (format: local:remote)"
    print_info "Press Enter with empty input to finish"

    local custom_ports=()
    while true; do
        read -p "Port mapping (e.g., 30080:30080): " port_mapping
        if [[ -z "$port_mapping" ]]; then
            break
        fi

        if [[ "$port_mapping" =~ ^[0-9]+:[0-9]+$ ]]; then
            custom_ports+=("$port_mapping")
            print_success "Added: $port_mapping"
        else
            print_warning "Invalid format. Use format: local_port:remote_port"
        fi
    done

    if [[ ${#custom_ports[@]} -eq 0 ]]; then
        print_info "No additional ports specified"
        echo ""
    else
        # Add custom ports to additional ports
        ADDITIONAL_PORTS=("${custom_ports[@]}")
        echo ""
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-proxy)
            ENABLE_SOCKS_PROXY=false
            shift
            ;;
        --socks-port)
            SOCKS_PORT="$2"
            shift 2
            ;;
        --custom-ports)
            get_custom_ports
            shift
            ;;
        --key)
            SSH_KEY="$2"
            shift 2
            ;;
        --user)
            SSH_USER="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "Connecting to Minikube instance..."
    echo ""

    # Get instance IP
    print_info "Getting Minikube instance IP from Terraform..."
    INSTANCE_IP=$(get_instance_ip)
    print_success "Found instance: $INSTANCE_IP"
    echo ""

    # Build SSH command
    local ssh_cmd="ssh"

    # Add SSH key if specified
    if [[ -n "$SSH_KEY" ]]; then
        if [[ ! -f "$SSH_KEY" ]]; then
            print_error "SSH key not found: $SSH_KEY"
            exit 1
        fi
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
        print_info "Using SSH key: $SSH_KEY"
    else
        print_info "Using default SSH configuration"
    fi
    echo ""

    # Add default port forwarding for API server
    print_info "Default port forwarding:"
    for port in "${DEFAULT_PORTS[@]}"; do
        local local_port="${port%%:*}"
        local remote_port="${port##*:}"
        echo "  localhost:${local_port} → minikube:${remote_port}"
        ssh_cmd="$ssh_cmd -L ${local_port}:192.168.49.2:${remote_port}"
    done
    echo ""

    # Add SOCKS proxy
    if [[ "$ENABLE_SOCKS_PROXY" == true ]]; then
        ssh_cmd="$ssh_cmd -D ${SOCKS_PORT}"
        print_info "SOCKS proxy enabled:"
        echo "  SOCKS5 proxy: localhost:${SOCKS_PORT}"
        echo ""
    else
        print_info "SOCKS proxy disabled"
        echo ""
    fi

    # Add additional port forwarding if specified
    if [[ ${#ADDITIONAL_PORTS[@]} -gt 0 ]]; then
        print_info "Additional port forwarding:"
        for port in "${ADDITIONAL_PORTS[@]}"; do
            local local_port="${port%%:*}"
            local remote_port="${port##*:}"
            echo "  localhost:${local_port} → minikube:${remote_port}"
            ssh_cmd="$ssh_cmd -L ${local_port}:192.168.49.2:${remote_port}"
        done
        echo ""
    fi

    print_success "Connecting to ${SSH_USER}@${INSTANCE_IP}..."
    print_info "Press Ctrl+D or type 'exit' to disconnect"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Execute SSH connection
    $ssh_cmd -o EnableEscapeCommandline=yes "${SSH_USER}@${INSTANCE_IP}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Disconnected from Minikube instance"
}

# Run main function
main
