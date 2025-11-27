#!/usr/bin/env bash
# Setup script for Fedora distrobox development environment
# Run this script inside your distrobox container or it will create one for you

set -euo pipefail

CONTAINER_NAME="${1:-fedora-dev}"
FEDORA_VERSION="41"

echo "=================================================="
echo "Fedora Distrobox Development Environment Setup"
echo "Container: ${CONTAINER_NAME}"
echo "=================================================="

# Check if we're already inside a distrobox
if [ -f /run/.containerenv ]; then
    echo "✓ Already inside a container, proceeding with installation..."
    INSIDE_CONTAINER=true
else
    echo "→ Not in a container, will create/enter distrobox..."
    INSIDE_CONTAINER=false
fi

install_packages() {
    echo ""
    echo "→ Installing development packages..."

    # Development Languages
    echo "  - Installing Python, Go, and Rust..."
    sudo dnf install -y \
        python3 \
        python3-pip \
        python3-devel \
        golang \
        cargo \
        rust \
        rust-src \
        rust-analyzer

    # VS Code
    echo "  - Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update || true
    sudo dnf install -y code

    # Additional useful dev tools
    echo "  - Installing additional development tools..."
    sudo dnf install -y \
        git \
        neovim \
        tmux \
        ripgrep \
        fd-find \
        fzf \
        bat \
        eza \
        jq \
        yq \
        tree \
        htop \
        curl \
        wget \
        make \
        gcc \
        gcc-c++ \
        cmake \
        autoconf \
        automake \
        libtool \
        pkg-config

    echo ""
    echo "✓ All packages installed successfully!"
}

configure_shell() {
    echo ""
    echo "→ Configuring shell environment..."

    # Add cargo bin to PATH if not already there
    if ! grep -q 'cargo/bin' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        echo "  ✓ Added cargo bin to PATH in ~/.bashrc"
    fi

    # Add helpful aliases
    if ! grep -q 'Development aliases' ~/.bashrc 2>/dev/null; then
        cat >> ~/.bashrc << 'EOF'

# Development aliases
alias ls='eza'
alias cat='bat'
alias find='fd'
alias grep='rg'

EOF
        echo "  ✓ Added development aliases to ~/.bashrc"
    fi

    echo "✓ Shell configuration complete!"
}

show_completion_message() {
    echo ""
    echo "=================================================="
    echo "✓ Development environment setup complete!"
    echo "=================================================="
    echo ""
    echo "Installed tools:"
    echo "  Languages: Python 3, Go, Rust (cargo, rustc, rust-analyzer)"
    echo "  Editors: VS Code, Neovim"
    echo "  CLI Tools: ripgrep, fd, fzf, bat, eza, jq, yq, and more"
    echo "  Build Tools: gcc, cmake, make, autoconf, and more"
    echo ""

    if [ "$INSIDE_CONTAINER" = false ]; then
        echo "To enter your development container, run:"
        echo "  distrobox enter ${CONTAINER_NAME}"
    else
        echo "Reload your shell to apply changes:"
        echo "  source ~/.bashrc"
    fi
    echo ""
    echo "Recommended VS Code extensions:"
    echo "  - ms-python.python"
    echo "  - rust-lang.rust-analyzer"
    echo "  - golang.go"
    echo "  - github.copilot"
    echo "  - esbenp.prettier-vscode"
    echo "  - eamodio.gitlens"
    echo ""
}

# Main execution
if [ "$INSIDE_CONTAINER" = false ]; then
    # Check if container exists
    if distrobox list | grep -q "^${CONTAINER_NAME} "; then
        echo "→ Container '${CONTAINER_NAME}' already exists"
        echo "→ Entering container to install packages..."
        distrobox enter "${CONTAINER_NAME}" -- bash -c "$(cat "$0")"
    else
        echo "→ Creating new distrobox container: ${CONTAINER_NAME}"
        distrobox create --name "${CONTAINER_NAME}" --image "fedora:${FEDORA_VERSION}"
        echo "→ Entering container to install packages..."
        distrobox enter "${CONTAINER_NAME}" -- bash -c "$(cat "$0")"
    fi
else
    # We're inside the container, do the actual installation
    install_packages
    configure_shell
    show_completion_message
fi
