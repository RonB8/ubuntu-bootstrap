#!/usr/bin/env bash
# Developer aliases — sourced by .zshrc and .bashrc

# ── Navigation ─────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ── Listing ────────────────────────────────────────────────────────────────
alias ls='ls --color=auto -F'
alias ll='ls -lhF --color=auto'
alias la='ls -lahF --color=auto'
alias lt='ls -lahFt --color=auto'     # Sort by modification time
alias l.='ls -d .* --color=auto'      # Show dotfiles only

# ── Git shortcuts ──────────────────────────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpl='git pull --rebase'
alias gl="git log --oneline --graph --decorate --all"
alias gd='git diff'
alias gds='git diff --staged'
alias gst='git stash'
alias gstp='git stash pop'

# ── Docker shortcuts ───────────────────────────────────────────────────────
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images'
alias drm='docker rm $(docker ps -aq)'           # Remove all stopped containers
alias drmi='docker rmi $(docker images -q)'      # Remove all images
alias dlogs='docker logs -f'
alias dexec='docker exec -it'
alias dprune='docker system prune -af --volumes'

# ── System utilities ───────────────────────────────────────────────────────
alias cls='clear'
alias h='history'
alias ports='ss -tulnp'              # Show listening ports
alias myip='curl -s ifconfig.me'
alias meminfo='free -h'
alias diskinfo='df -h'
alias cpuinfo='lscpu'
alias topcpu='ps aux --sort=-%cpu | head -15'
alias topmem='ps aux --sort=-%mem | head -15'

# ── Networking ─────────────────────────────────────────────────────────────
alias ping='ping -c 5'
alias wget='wget -c'                 # Resume downloads by default
alias nmap='nmap -v'

# ── Safety guards ──────────────────────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ── Editors ────────────────────────────────────────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ── Development ────────────────────────────────────────────────────────────
alias mk='make'
alias mkc='make clean'
alias rust-new='cargo new'
alias rust-run='cargo run'
alias rust-build='cargo build --release'
alias rust-test='cargo test'
alias rust-fmt='cargo fmt && cargo clippy'

# ── Grep with color ────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ── Misc helpers ───────────────────────────────────────────────────────────
alias path='echo -e "${PATH//:/\\n}"'    # Print PATH entries one per line
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# Quick HTTP server in current directory (requires Python 3)
alias serve='python3 -m http.server 8000'

# Show top 10 largest files in current directory tree
alias bigfiles='du -ah . | sort -rh | head -10'
