#!/usr/bin/env bash
# Logging utilities — all output goes to stdout and a rotating log file.

LOG_FILE="${LOG_FILE:-/var/log/dev-setup.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

_timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

_write() {
    local level="$1"; shift
    local msg="[$(_timestamp)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_info()    { _write "INFO " "$@"; }
log_success() { _write "OK   " "$@"; }
log_warn()    { _write "WARN " "$@"; }
log_error()   { _write "ERROR" "$@" >&2; }

log_section() {
    local border="========================================"
    _write "INFO " "$border"
    _write "INFO " "  $*"
    _write "INFO " "$border"
}

# Call at the start of every module to ensure the log file is writable.
init_logger() {
    touch "$LOG_FILE" 2>/dev/null || {
        LOG_FILE="/tmp/dev-setup.log"
        touch "$LOG_FILE"
    }
    chmod 640 "$LOG_FILE" 2>/dev/null || true
}
