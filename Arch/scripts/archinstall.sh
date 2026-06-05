#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

ARCHINSTALL_CONFIG="${HOME}/arch/archinstall/user_configuration.json"
ARCHINSTALL_CREDS="${HOME}/arch/archinstall/user_credentials.json"

# ─── Archinstall Setup ────────────────────────────────────────────────────────

run_archinstall() {
    log_step "Checking ARCHINSTALL_CONFIG file ⏳"
    if [[ ! -f "${ARCHINSTALL_CONFIG}" ]]; then
        log_error "Archinstall configuration file not found at ${ARCHINSTALL_CONFIG} ❌"
        return 1
    fi

    log_step "Checking ARCHINSTALL_CREDS file ⏳"
    if [[ ! -f "${ARCHINSTALL_CREDS}" ]]; then
        log_error "Archinstall credentials file not found at ${ARCHINSTALL_CREDS} ❌"
        return 1
    fi

    log_step "Starting archinstall ⏳"
    if sudo archinstall --config "${ARCHINSTALL_CONFIG}" --creds "${ARCHINSTALL_CREDS}"; then
        clear
        log_success "archinstall completed successfully ✅"
    else
        log_error "archinstall failed ❌"
        return 1
    fi

    return 0
}

post_install() {
    log_step "Performing post-installation setup ⏳"
    
    log_step "Cloning repository... ⏳"
    sudo arch-chroot /mnt git clone https://github.com/xwildhagen/arch.git /home/wildhagen/arch || {
        log_error "Could not clone repository ❌"
        return 1
    }

    log_step "Setting permissions ⏳"
    sudo arch-chroot /mnt chown -R 1000:1000 "/home/wildhagen/" || {
        log_error "Could not set permissions ❌"
        return 1
    }
    sudo arch-chroot /mnt chmod -R +rx "/home/wildhagen/" || {
        log_error "Could not set permissions ❌"
        return 1
    }
    
    log_success "Post-installation setup complete ✅"

    return 0
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

archinstall_main() {
    log_step "Starting ARCHINSTALL SETUP ⏳"

    if ! run_archinstall; then
        log_error "ARCHINSTALL FAILED ❌"
        return 1
    fi

    if ! post_install; then
        log_error "POST-INSTALL FAILED ❌"
        return 1
    fi

    log_success "ARCHINSTALL SETUP COMPLETE 🎉"

    log_warn "Rebooting the system ⚠️"
    sudo reboot

    return 0
}