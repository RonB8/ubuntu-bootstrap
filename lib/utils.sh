#!/usr/bin/env bash
# Utility helpers shared across all modules.

# Return 0 if a command exists on PATH.
command_exists() { command -v "$1" &>/dev/null; }

# Return 0 if the calling user is root (UID 0).
is_root() { [[ "$EUID" -eq 0 ]]; }

# Abort with an error message when not running as root.
require_root() {
    if ! is_root; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
}

# Install one or more apt packages only when they are not already installed.
# Usage: apt_install_if_missing pkg1 pkg2 ...
apt_install_if_missing() {
    local to_install=()
    for pkg in "$@"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            to_install+=("$pkg")
        else
            log_info "Package already installed, skipping: $pkg"
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing: ${to_install[*]}"
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
    fi
}

# Append a line to a file only when the line is not already present.
# Usage: append_if_missing "line" /path/to/file
append_if_missing() {
    local line="$1"
    local file="$2"
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Replace or insert a key=value pair in a config file (handles KEY value too).
# Usage: set_config_value KEY value /path/to/file
set_config_value() {
    local key="$1"
    local value="$2"
    local file="$3"
    if grep -qE "^#?\s*${key}\s" "$file" 2>/dev/null; then
        sed -i "s|^#\?\s*${key}\s.*|${key} ${value}|" "$file"
    else
        echo "${key} ${value}" >> "$file"
    fi
}
