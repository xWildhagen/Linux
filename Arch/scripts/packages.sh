#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../.shared/helpers.sh"
source "${SCRIPT_DIR}/conf/packages.conf"

# ─── Packages Setup ─────────────────────────────────────────────────────────────

# https://github.com/Jguer/yay
install_yay() {
    log_step "Checking for existing Yay installation... ⏳"
    if command -v yay &> /dev/null; then
        log_success "Yay is already installed ✅"
        return 0
    fi

    cd "${HOME}" || {
        log_error "Could not change to home directory ❌"
        return 1
    }
    
    log_step "Installing git and base-devel... ⏳"
    sudo pacman -S --noconfirm --needed git base-devel || {
        log_error "Failed to install git and base-devel ❌"
        return 1
    }
    
    if [[ -d "yay" ]]; then
        log_step "Pulling latest Yay changes... ⏳"
        (cd yay && git pull) || {
            log_error "Failed to pull latest Yay changes ❌"
            return 1
        }
    else
        log_step "Cloning Yay repository... ⏳"
        git clone https://aur.archlinux.org/yay.git || {
            log_error "Failed to clone Yay repository ❌"
            return 1
        }
    fi

    log_step "Installing Yay... ⏳"
    cd yay || {
        log_error "Could not find Yay directory ❌"
        return 1
    }
    makepkg -si --noconfirm || {
        log_error "Failed to build and install Yay ❌"
        return 1
    }

    log_step "Cleaning up Yay build files... ⏳"
    cd "${HOME}" || {
        log_error "Could not change to home directory ❌"
        return 1
    }
    rm -rf yay

    log_success "Yay installed successfully ✅"

    return 0
}

remove_packages() {
    log_step "Checking REMOVE_PACKAGES array ⏳"
    if [[ -z "${REMOVE_PACKAGES+x}" || ${#REMOVE_PACKAGES[@]} -eq 0 ]]; then
        log_error "REMOVE_PACKAGES array is not defined or is empty ❌"
        return 1
    fi

    log_step "Removing packages... ⏳"
    for package in "${REMOVE_PACKAGES[@]}"; do
        if pacman -Q | awk '{print $1}' | grep -xq "${package}"; then
            log_info "Removing (pacman): ${package} ℹ️"
            sudo pacman -Rns --noconfirm "${package}" || {
                log_error "Failed to remove ${package} ❌"
                return 1
            }
        elif command -v yay &>/dev/null && yay -Q | awk '{print $1}' | grep -xq "${package}"; then
            log_info "Removing (yay): ${package} ℹ️"
            yay -Rns --noconfirm "${package}" || {
                log_error "Failed to remove ${package} ❌"
                return 1
            }
        else
            log_success "${package} not found ✅"
        fi
    done

    return 0
}

install_packages() {
    install_yay || {
        log_error "Failed to install Yay ❌"
        return 1
    }

    log_step "Checking INSTALL_PACKAGES array ⏳"
    if [[ -z "${INSTALL_PACKAGES+x}" || ${#INSTALL_PACKAGES[@]} -eq 0 ]]; then
        log_error "INSTALL_PACKAGES array is not defined or is empty ❌"
        return 1
    fi

    log_step "Updating installed pacman and yay packages... ⏳"
    sudo pacman -Syu --noconfirm || {
        log_error "Failed to update package database ❌"
        return 1
    }
    yay -Syu --noconfirm || {
        log_error "Failed to update AUR packages ❌"
        return 1
    }

    log_step "Installing packages... ⏳"
    for package in "${INSTALL_PACKAGES[@]}"; do
        if pacman -Si "${package}" &>/dev/null; then
            log_info "Installing (pacman): ${package} ℹ️"
            sudo pacman -S --noconfirm --needed "${package}" || {
                log_error "Failed to install ${package} ❌"
                return 1
            }
        elif command -v yay &>/dev/null && yay -Si "${package}" &>/dev/null; then
            log_info "Installing (yay): ${package} ℹ️"
            yay -S --noconfirm --needed "${package}" || {
                log_error "Failed to install ${package} ❌"
                return 1
            }
        else
            log_error "${package} not found in repositories ❌"
        fi
    done

    return 0
}

get_repositories() {
    log_step "Checking REPOSITORIES array ⏳"
    if [[ -z "${REPOSITORIES+x}" || ${#REPOSITORIES[@]} -eq 0 ]]; then
        log_error "REPOSITORIES array is not defined or is empty ❌"
        return 1
    fi
    
    cd "${HOME}" || {
        log_error "Could not change to home directory ❌"
        return 1
    }

    log_step "Getting repositories... ⏳"
    for repository in "${REPOSITORIES[@]}"; do
        local repo destination
        repo=$(echo "${repository}" | awk '{print $1}')
        destination=$(echo "${repository}" | awk '{print $2}')

        if [[ -z "${destination}" ]]; then
            destination=$(basename "${repo}")
        fi

        if [[ -d "${destination}" ]]; then
            log_info "Pulling latest ${repo} changes... ℹ️"
            git -C "${destination}" pull || {
                log_error "Failed to pull latest ${repo} changes ❌"
                return 1
            }
        else
            log_info "Cloning ${repo} repository... ℹ️"
            git clone "https://github.com/${repo}" "${destination}" || {
                log_error "Failed to clone ${repo} repository ❌"
                return 1
            }
        fi
    done

    return 0
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

packages_main() {
    log_step "Starting PACKAGE INSTALLATION ⏳"

    if ! remove_packages; then
        log_error "PACKAGE REMOVAL FAILED ❌"
        return 1
    fi

    if ! install_packages; then
        log_error "PACKAGE INSTALLATION FAILED ❌"
        return 1
    fi

    if ! get_repositories; then
        log_error "GETTING REPOSITORIES FAILED ❌"
        return 1
    fi

    log_success "PACKAGE INSTALLATION COMPLETE 🎉"

    return 0
}
