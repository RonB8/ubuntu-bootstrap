#!/usr/bin/env bash
# environment.sh — Zsh, Starship prompt, Neovim, and developer aliases.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# Zsh
# ---------------------------------------------------------------------------
install_zsh() {
    log_section "Installing Zsh"
    apt_install_if_missing zsh

    local username="${DEV_USER:-devuser}"
    local user_shell
    user_shell=$(getent passwd "$username" | cut -d: -f7)
    local zsh_path
    zsh_path=$(command -v zsh)

    if [[ "$user_shell" == "$zsh_path" ]]; then
        log_info "Zsh is already the default shell for '$username'"
    else
        chsh -s "$zsh_path" "$username"
        log_success "Default shell for '$username' changed to Zsh"
    fi
}

# ---------------------------------------------------------------------------
# Starship cross-shell prompt
# ---------------------------------------------------------------------------
install_starship() {
    log_section "Installing Starship prompt"

    if command_exists starship; then
        log_info "Starship already installed: $(starship --version)"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        log_success "Starship installed: $(starship --version)"
    fi

    # Deploy Starship config for the dev user.
    local username="${DEV_USER:-devuser}"
    local config_dir="/home/${username}/.config"
    mkdir -p "$config_dir"

    if [[ -f "${SCRIPT_DIR}/config/starship.toml" ]]; then
        cp "${SCRIPT_DIR}/config/starship.toml" "${config_dir}/starship.toml"
        chown "${username}:${username}" "${config_dir}/starship.toml"
        log_success "Starship config deployed"
    else
        log_warn "config/starship.toml not found — using Starship defaults"
    fi

    # Activate Starship in Zsh and Bash profiles (idempotent).
    local zshrc="/home/${username}/.zshrc"
    local bashrc="/home/${username}/.bashrc"
    append_if_missing 'eval "$(starship init zsh)"'  "$zshrc"
    append_if_missing 'eval "$(starship init bash)"' "$bashrc"
    chown "${username}:${username}" "$zshrc" "$bashrc"
}

# ---------------------------------------------------------------------------
# Neovim (latest stable AppImage)
# ---------------------------------------------------------------------------
install_neovim() {
    log_section "Installing Neovim"

    if command_exists nvim; then
        log_info "Neovim already installed: $(nvim --version | head -1)"
        return 0
    fi

    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    local install_dir="/opt/nvim"
    local tmp_archive="/tmp/nvim-linux-x86_64.tar.gz"

    curl -fsSL "$nvim_url" -o "$tmp_archive"
    mkdir -p "$install_dir"
    tar -xzf "$tmp_archive" --strip-components=1 -C "$install_dir"
    rm -f "$tmp_archive"

    ln -sf "${install_dir}/bin/nvim" /usr/local/bin/nvim
    log_success "Neovim installed: $(nvim --version | head -1)"
}

# ---------------------------------------------------------------------------
# Developer aliases
# ---------------------------------------------------------------------------
install_aliases() {
    log_section "Installing developer aliases"

    local username="${DEV_USER:-devuser}"
    local aliases_src="${SCRIPT_DIR}/config/aliases.sh"
    local aliases_dest="/home/${username}/.aliases"

    if [[ -f "$aliases_src" ]]; then
        cp "$aliases_src" "$aliases_dest"
        chown "${username}:${username}" "$aliases_dest"
        log_success "Aliases file deployed to $aliases_dest"
    else
        log_warn "config/aliases.sh not found — skipping aliases"
        return 0
    fi

    # Source aliases from both Zsh and Bash init files (idempotent).
    for rc in "/home/${username}/.zshrc" "/home/${username}/.bashrc"; do
        append_if_missing '[[ -f ~/.aliases ]] && source ~/.aliases' "$rc"
    done
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------
run_environment() {
    install_zsh
    install_starship
    install_neovim
    install_aliases
}
