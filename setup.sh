#!/usr/bin/env bash
# =============================================================================
# setup.sh — Main entry point for Ubuntu Developer Environment Setup
#
# Usage:
#   sudo DEV_USER=myuser bash setup.sh [--security] [--tools] [--environment]
#
# With no flags, all three modules are executed in order.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate the project root (works even when called from another directory)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Source shared libraries
# ---------------------------------------------------------------------------
# shellcheck source=lib/logger.sh
source "${SCRIPT_DIR}/lib/logger.sh"
# shellcheck source=lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"
# shellcheck source=lib/security.sh
source "${SCRIPT_DIR}/lib/security.sh"
# shellcheck source=lib/tools.sh
source "${SCRIPT_DIR}/lib/tools.sh"
# shellcheck source=lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
export DEV_USER="${DEV_USER:-devuser}"
export LOG_FILE="${LOG_FILE:-/var/log/dev-setup.log}"

RUN_SECURITY=false
RUN_TOOLS=false
RUN_ENVIRONMENT=false

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    RUN_SECURITY=true
    RUN_TOOLS=true
    RUN_ENVIRONMENT=true
else
    for arg in "$@"; do
        case "$arg" in
            --security)    RUN_SECURITY=true ;;
            --tools)       RUN_TOOLS=true ;;
            --environment) RUN_ENVIRONMENT=true ;;
            --help|-h)
                cat <<EOF
Usage: sudo bash setup.sh [OPTIONS]

Options:
  --security      Configure UFW, create sudo user, harden SSH
  --tools         Install GCC, Make, GDB, Git, Docker, Rust
  --environment   Install Zsh, Starship, Neovim, and aliases
  (no flags)      Run all modules

Environment variables:
  DEV_USER   Username for the non-root dev user  (default: devuser)
  LOG_FILE   Path to the log file                (default: /var/log/dev-setup.log)
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $arg  (use --help for usage)" >&2
                exit 1
                ;;
        esac
    done
fi

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
init_logger
require_root

log_section "Ubuntu Developer Environment Setup"
log_info "Log file : $LOG_FILE"
log_info "Dev user : $DEV_USER"
log_info "Modules  : security=$RUN_SECURITY  tools=$RUN_TOOLS  environment=$RUN_ENVIRONMENT"

# Verify we are on a Debian/Ubuntu system.
if ! command_exists apt-get; then
    log_error "apt-get not found — this script requires Ubuntu/Debian."
    exit 1
fi

# ---------------------------------------------------------------------------
# System update (always runs to ensure a consistent baseline)
# ---------------------------------------------------------------------------
log_section "Updating system packages"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
log_success "System packages up to date"

# ---------------------------------------------------------------------------
# Module execution
# ---------------------------------------------------------------------------
FAILED_MODULES=()

run_module() {
    local name="$1"
    local fn="$2"
    if eval "$fn"; then
        log_success "Module [$name] completed successfully"
    else
        log_error "Module [$name] FAILED (exit code $?)"
        FAILED_MODULES+=("$name")
    fi
}

[[ "$RUN_SECURITY"    == true ]] && run_module "security"    "run_security"
[[ "$RUN_TOOLS"       == true ]] && run_module "tools"       "run_tools"
[[ "$RUN_ENVIRONMENT" == true ]] && run_module "environment" "run_environment"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log_section "Setup Summary"

if [[ ${#FAILED_MODULES[@]} -eq 0 ]]; then
    log_success "All modules completed successfully."
    log_info "Full log available at: $LOG_FILE"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Set a password for '$DEV_USER':  passwd $DEV_USER"
    log_info "  2. Copy your SSH public key:        ssh-copy-id $DEV_USER@<server-ip>"
    log_info "  3. Log in as '$DEV_USER' and verify the environment."
    exit 0
else
    log_error "The following modules failed: ${FAILED_MODULES[*]}"
    log_error "Review the log for details: $LOG_FILE"
    exit 1
fi
