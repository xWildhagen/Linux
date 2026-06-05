#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.shared/helpers.sh"

source "${SCRIPT_DIR}/scripts/archinstall.sh"
source "${SCRIPT_DIR}/scripts/packages.sh"
source "${SCRIPT_DIR}/scripts/home.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

AVAILABLE_COMMANDS=("archinstall" "packages" "home")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🖥️ Arch Linux Setup Script

Usage: ./main.sh [OPTION]

Options:
  --help         Show this help message
  --all          Run all setup steps
  --archinstall  Start archinstall
  --packages     Start package installation
  --home         Start home setup

Available commands: ${AVAILABLE_COMMANDS[*]}
EOF
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

run_commands() {
    local commands=("$@")

    for cmd in "${commands[@]}"; do
        local fn="${cmd}_main"
        if declare -f "${fn}" > /dev/null 2>&1; then
            "${fn}"
        else
            log_error "Unknown command: ${cmd} ❌"
            return 1
        fi
    done

    log_success "All requested setups completed successfully! 🎉"
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        return 0
    fi

    case "$1" in
        --all)
            run_commands "${AVAILABLE_COMMANDS[@]}"
            ;;
        --archinstall)
            run_commands "archinstall"
            ;;
        --packages)
            run_commands "packages"
            ;;
        --home)
            run_commands "home"
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1 ❌"
            echo ""
            usage
            return 1
            ;;
    esac
}

main "$@"
