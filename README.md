# Ubuntu Developer Environment Setup

A modular, idempotent Bash automation project that transforms a fresh Ubuntu Server into a fully configured development environment in a single command.

---

## Table of Contents

- [Purpose](#purpose)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Installed Components](#installed-components)
- [Configuration](#configuration)
- [Idempotency](#idempotency)
- [Logging](#logging)

---

## Purpose

Manually configuring a new server is error-prone and time-consuming. This project automates the entire post-installation workflow — from security hardening to developer tooling — so a machine is production-ready in minutes. Every step is logged, every module is independently re-runnable, and the script is safe to execute on a live system without breaking existing configuration.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Ubuntu Server 22.04 LTS or 24.04 LTS |
| **Privileges** | Must be run as `root` (via `sudo`) |
| **Internet access** | Required for package downloads |
| **Architecture** | `x86_64` (AMD64) |

> **Note:** The Neovim installer downloads a pre-built `x86_64` binary. On ARM64 systems, edit `install_neovim()` in `lib/environment.sh` to use the `nvim-linux-arm64.tar.gz` asset instead.

---

## Quick Start

```bash
# 1. Clone the repository onto your server
git clone https://github.com/your-org/ubuntu-dev-setup.git
cd ubuntu-dev-setup

# 2. Make scripts executable
chmod +x setup.sh lib/*.sh

# 3. Run the full setup (creates 'devuser' by default)
sudo bash setup.sh

# — OR — specify a custom username
sudo DEV_USER=alice bash setup.sh
```

After the script finishes, set a password for the new user and copy your SSH key:

```bash
sudo passwd alice
ssh-copy-id alice@<server-ip>
```

---

## Usage

```
sudo bash setup.sh [OPTIONS]

Options:
  --security      Configure UFW, create sudo user, harden SSH only
  --tools         Install build tools, Docker, and Rust only
  --environment   Install Zsh, Starship, Neovim, and aliases only
  (no flags)      Run all three modules in sequence
  --help          Show this help message

Environment variables:
  DEV_USER   Non-root username to create/configure  (default: devuser)
  LOG_FILE   Absolute path for the log file         (default: /var/log/dev-setup.log)
```

### Examples

```bash
# Run only the security module
sudo bash setup.sh --security

# Run tools and environment modules for user 'bob'
sudo DEV_USER=bob bash setup.sh --tools --environment

# Write logs to a custom location
sudo LOG_FILE=/tmp/setup.log bash setup.sh
```

---

## Project Structure

```
ubuntu-dev-setup/
├── setup.sh              # Main entry point — parses args, runs modules
├── README.md             # This file
├── lib/
│   ├── logger.sh         # Timestamped logging (info / success / warn / error)
│   ├── utils.sh          # Shared helpers (apt_install_if_missing, append_if_missing …)
│   ├── security.sh       # UFW rules, sudo user creation, SSH hardening
│   ├── tools.sh          # Build toolchain, Docker Engine, Rust via rustup
│   └── environment.sh    # Zsh, Starship prompt, Neovim, developer aliases
└── config/
    ├── starship.toml     # Starship prompt theme (deployed to ~/.config/)
    └── aliases.sh        # Developer aliases (deployed to ~/.aliases)
```

---

## Installed Components

### Security Module (`--security`)

| Component | What it does |
|-----------|-------------|
| **UFW** | Default-deny inbound; allows SSH (22), HTTP (80), HTTPS (443) |
| **Non-root user** | Creates `$DEV_USER`, adds to `sudo` and `docker` groups |
| **SSH hardening** | Disables root login and password auth; enables public-key only; sets idle timeout |

SSH settings applied to `/etc/ssh/sshd_config`:

```
PermitRootLogin         no
PasswordAuthentication  no
PubkeyAuthentication    yes
MaxAuthTries            3
ClientAliveInterval     300
ClientAliveCountMax     2
X11Forwarding           no
Protocol                2
```

> A timestamped backup of the original `sshd_config` is created before any changes, and `sshd -t` validates the new config before the service is restarted.

### Tools Module (`--tools`)

| Tool | Version |
|------|---------|
| GCC / G++ | Ubuntu repository (latest stable) |
| Make | Ubuntu repository |
| GDB | Ubuntu repository |
| Git | Ubuntu repository |
| Docker Engine | Official Docker CE repository |
| Docker Compose | Official Docker Compose plugin |
| Rust | Latest stable via `rustup` |

### Environment Module (`--environment`)

| Component | Details |
|-----------|---------|
| **Zsh** | Set as the default shell for `$DEV_USER` |
| **Starship** | Cross-shell prompt installed system-wide; custom theme deployed |
| **Neovim** | Latest stable release from official GitHub releases |
| **Aliases** | Deployed to `~/.aliases`, auto-sourced from `.zshrc` and `.bashrc` |

**Alias categories:**

- Navigation (`..`, `...`, `~`)
- Listing (`ll`, `la`, `lt`, `l.`)
- Git (`gs`, `ga`, `gc`, `gp`, `gl`, `gd`, …)
- Docker (`d`, `dc`, `dps`, `dlogs`, `dexec`, `dprune`, …)
- System utilities (`ports`, `myip`, `meminfo`, `diskinfo`, `topcpu`, …)
- Rust/Cargo (`rust-run`, `rust-build`, `rust-test`, `rust-fmt`)
- Safety guards (`rm`, `cp`, `mv` all prompt before overwriting)

---

## Configuration

### Customising the Starship prompt

Edit `config/starship.toml` before running the script, or modify it afterwards at `~/.config/starship.toml`. Full documentation: <https://starship.rs/config/>

### Adding aliases

Add entries to `config/aliases.sh` before running. On an already-configured machine, edit `~/.aliases` directly — changes take effect in the next shell session.

### Changing the SSH port

If you want a non-standard SSH port, add this call inside `harden_ssh()` in `lib/security.sh`:

```bash
set_config_value "Port" "2222" "$sshd_conf"
ufw allow 2222/tcp
```

---

## Idempotency

The script can be executed multiple times against the same machine without side effects:

- **Packages** — `apt_install_if_missing` checks `dpkg` before installing.
- **UFW rules** — UFW itself deduplicates rules on re-run.
- **Users** — `id $username` check skips `adduser` if the user exists.
- **SSH config** — `set_config_value` uses `sed` to replace rather than append.
- **Starship / Neovim** — Presence of the binary is checked before downloading.
- **Rust** — `rustup update stable` is called instead of a fresh install when Cargo exists.
- **Shell profiles** — `append_if_missing` uses `grep -qxF` to prevent duplicate lines.

---

## Logging

All output is simultaneously printed to the terminal and appended to `$LOG_FILE` (default: `/var/log/dev-setup.log`).

Log format:

```
[2024-10-01 14:30:00] [INFO ] Updating system packages
[2024-10-01 14:30:45] [OK   ] System packages up to date
[2024-10-01 14:30:45] [INFO ] ========================================
[2024-10-01 14:30:45] [INFO ]   Configuring UFW firewall
```

If the process lacks write permission to `/var/log/`, the log falls back to `/tmp/dev-setup.log` automatically.
