#!/usr/bin/env bash
# security.sh — UFW firewall rules, SSH hardening, and non-root sudo user.

# Sourced by setup.sh; logger.sh and utils.sh are already loaded.

# ---------------------------------------------------------------------------
# UFW — Uncomplicated Firewall
# ---------------------------------------------------------------------------
configure_ufw() {
    log_section "Configuring UFW firewall"

    apt_install_if_missing ufw

    # Idempotent: ufw status reports 'active' if already enabled.
    local status
    status=$(ufw status | awk '{print $2; exit}')

    # Set sane defaults before enabling.
    ufw default deny incoming  &>/dev/null
    ufw default allow outgoing &>/dev/null

    # Allow essential services (rules are skipped if already present).
    for rule in "ssh" "80/tcp" "443/tcp"; do
        ufw allow "$rule" &>/dev/null
        log_info "UFW rule ensured: $rule"
    done

    if [[ "$status" != "active" ]]; then
        ufw --force enable
        log_success "UFW enabled"
    else
        log_success "UFW already active — rules updated"
    fi
}

# ---------------------------------------------------------------------------
# Non-root sudo user
# ---------------------------------------------------------------------------
create_sudo_user() {
    local username="${DEV_USER:-devuser}"
    log_section "Ensuring non-root sudo user: $username"

    if id "$username" &>/dev/null; then
        log_info "User '$username' already exists, skipping creation"
    else
        # --disabled-password: no password login until explicitly set.
        adduser --disabled-password --gecos "" "$username"
        log_success "User '$username' created"
    fi

    # Idempotent: usermod -aG is safe to run repeatedly.
    usermod -aG sudo "$username"
    log_success "User '$username' added to sudo group"

    # Ensure the user's home directory exists and has correct ownership.
    local home_dir="/home/$username"
    mkdir -p "$home_dir"
    chown -R "$username:$username" "$home_dir"
}

# ---------------------------------------------------------------------------
# SSH hardening
# ---------------------------------------------------------------------------
harden_ssh() {
    log_section "Hardening SSH configuration"

    local sshd_conf="/etc/ssh/sshd_config"
    local backup="${sshd_conf}.bak.$(date +%Y%m%d%H%M%S)"

    # Back up the original only once.
    if [[ ! -f "${sshd_conf}.bak.original" ]]; then
        cp "$sshd_conf" "${sshd_conf}.bak.original"
        log_info "Original sshd_config backed up to ${sshd_conf}.bak.original"
    fi
    cp "$sshd_conf" "$backup"
    log_info "Working backup created: $backup"

    # Apply hardening settings (set_config_value is idempotent).
    set_config_value "PermitRootLogin"          "no"                "$sshd_conf"
    set_config_value "PasswordAuthentication"   "no"                "$sshd_conf"
    set_config_value "PubkeyAuthentication"     "yes"               "$sshd_conf"
    set_config_value "X11Forwarding"            "no"                "$sshd_conf"
    set_config_value "MaxAuthTries"             "3"                 "$sshd_conf"
    set_config_value "ClientAliveInterval"      "300"               "$sshd_conf"
    set_config_value "ClientAliveCountMax"      "2"                 "$sshd_conf"
    set_config_value "AllowAgentForwarding"     "no"                "$sshd_conf"
    set_config_value "Protocol"                 "2"                 "$sshd_conf"

    # Validate before restarting — prevents locking ourselves out.
    if sshd -t -f "$sshd_conf"; then
        systemctl restart ssh
        log_success "SSH hardened and restarted"
    else
        log_error "sshd_config validation failed — reverting to backup"
        cp "$backup" "$sshd_conf"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------
run_security() {
    configure_ufw
    create_sudo_user
    harden_ssh
}
