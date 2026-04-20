#!/usr/bin/env bash
# tools.sh — Install GCC, Make, GDB, Git, Docker (+ Compose), and Rust.

# ---------------------------------------------------------------------------
# Build toolchain
# ---------------------------------------------------------------------------
install_build_tools() {
    log_section "Installing build toolchain (GCC / Make / GDB / Git)"
    apt_install_if_missing \
        gcc \
        g++ \
        make \
        gdb \
        git \
        curl \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common

    log_success "Build toolchain installed"
    log_info "GCC:  $(gcc --version | head -1)"
    log_info "Make: $(make --version | head -1)"
    log_info "GDB:  $(gdb --version  | head -1)"
    log_info "Git:  $(git --version)"
}

# ---------------------------------------------------------------------------
# Docker Engine + Docker Compose plugin
# ---------------------------------------------------------------------------
install_docker() {
    log_section "Installing Docker Engine"

    # Idempotency guard — skip if docker is already installed.
    if command_exists docker; then
        log_info "Docker already installed: $(docker --version)"
    else
        # Remove legacy packages that conflict with the official repo.
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            apt-get remove -y "$pkg" &>/dev/null || true
        done

        # Add Docker's official GPG key.
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" \
            | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the stable repository.
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
          > /etc/apt/sources.list.d/docker.list

        apt-get update -qq
        apt_install_if_missing \
            docker-ce \
            docker-ce-cli \
            containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin

        systemctl enable --now docker
        log_success "Docker installed: $(docker --version)"
    fi

    # Add the dev user to the docker group so they can use Docker without sudo.
    local username="${DEV_USER:-devuser}"
    if id "$username" &>/dev/null; then
        usermod -aG docker "$username"
        log_success "User '$username' added to docker group"
    fi

    # Verify Docker Compose plugin.
    if docker compose version &>/dev/null; then
        log_success "Docker Compose: $(docker compose version)"
    else
        log_warn "Docker Compose plugin not found — check installation"
    fi
}

# ---------------------------------------------------------------------------
# Rust toolchain  (installed as the target user, not root)
# ---------------------------------------------------------------------------
install_rust() {
    log_section "Installing Rust toolchain"

    local username="${DEV_USER:-devuser}"
    local rustup_home="/home/${username}/.rustup"
    local cargo_home="/home/${username}/.cargo"

    if [[ -f "${cargo_home}/bin/rustc" ]]; then
        log_info "Rust already installed for user '$username', running rustup update"
        sudo -u "$username" bash -c \
            "export RUSTUP_HOME=${rustup_home} CARGO_HOME=${cargo_home}; \
             ${cargo_home}/bin/rustup update stable"
    else
        log_info "Downloading and installing rustup for user '$username'"
        sudo -u "$username" bash -c \
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
             | RUSTUP_HOME=${rustup_home} CARGO_HOME=${cargo_home} \
               sh -s -- -y --default-toolchain stable --no-modify-path"
        chown -R "${username}:${username}" "$rustup_home" "$cargo_home"
        log_success "Rust installed: $(sudo -u "$username" ${cargo_home}/bin/rustc --version)"
    fi

    # Persist Cargo bin in the user's PATH via their shell profile.
    local profile="/home/${username}/.profile"
    append_if_missing 'export PATH="$HOME/.cargo/bin:$PATH"' "$profile"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------
run_tools() {
    install_build_tools
    install_docker
    install_rust
}
