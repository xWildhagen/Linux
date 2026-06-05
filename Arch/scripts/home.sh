#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../.shared/helpers.sh"
source "${SCRIPT_DIR}/conf/files.conf"

# ─── Home Setup ───────────────────────────────────────────────────────────────

delete_files() {
    log_step "Checking DELETE_FILES array ⏳"
    if [[ -z "${DELETE_FILES+x}" || ${#DELETE_FILES[@]} -eq 0 ]]; then
        log_error "DELETE_FILES array is not defined or is empty ❌"
        return 1
    fi

    for file in "${DELETE_FILES[@]}"; do
        if [[ -e "${HOME}/${file}" ]]; then
            log_step "Deleting ${file}... ⏳"
            sudo rm -r -- "${HOME}/${file}" || {
                log_error "Could not delete ${file} ❌"
                return 1
            }
        fi
    done

    return 0
}

create_files() {
    log_step "Checking KEEP_FILES array ⏳"
    if [[ -z "${KEEP_FILES+x}" || ${#KEEP_FILES[@]} -eq 0 ]]; then
        log_error "KEEP_FILES array is not defined or is empty ❌"
        return 1
    fi

    for file in "${KEEP_FILES[@]}"; do
        local full_path="${HOME}/${file}"
        if [[ "${file}" == */ ]]; then
            if [[ ! -d "${full_path}" ]]; then
                log_step "Creating directory ${file}... ⏳"
                mkdir -p -- "${full_path}" || {
                    log_error "Could not create directory ${file} ❌"
                    return 1
                }
            fi
        else
            local parent_dir
            parent_dir=$(dirname "${full_path}")
            if [[ ! -d "${parent_dir}" ]]; then
                mkdir -p -- "${parent_dir}" || {
                    log_error "Could not create directory for ${file} ❌"
                    return 1
                }
            fi
            if [[ ! -f "${full_path}" ]]; then
                log_step "Creating file ${file}... ⏳"
                touch -- "${full_path}" || {
                    log_error "Could not create file ${file} ❌"
                    return 1
                }
            fi
        fi
    done

    return 0
}

link_files() {
    log_step "Checking DOTFILES array ⏳"
    if [[ -z "${DOTFILES+x}" || ${#DOTFILES[@]} -eq 0 ]]; then
        log_error "DOTFILES array is not defined or is empty ❌"
        return 1
    fi

    log_step "Creating symbolic links ⏳"
    for dotfile in "${DOTFILES[@]}"; do
        local src="" tgt=""
        read -r src tgt <<< "${dotfile}"
        [[ -z "${tgt}" ]] && tgt="${src}"
        
        local source_path="${HOME}/arch/dotfiles/${src}"
        local target_path="${tgt}"
        local target_dir
        target_dir=$(dirname "${target_path}")
        
        log_info "Linking ${target_path}... ℹ️"
        if [[ ! -d "${target_dir}" ]]; then
            log_info "Creating directory: ${target_dir} ℹ️"
            mkdir -p -- "${target_dir}" || sudo mkdir -p -- "${target_dir}" || { 
                log_error "Could not create directory ${target_dir} ❌"
                return 1
            }
        fi
        
        sudo rm -rf -- "${target_path}"
        ln -sf -- "${source_path}" "${target_path}" 2>/dev/null || sudo ln -sf -- "${source_path}" "${target_path}" || {
            log_error "Could not link ${target_path} ❌"
            return 1
        }
    done

    if command -v hyprctl &> /dev/null; then
        hyprctl reload >/dev/null 2>&1 || log_warn "Hyprctl reload failed ⚠️"
    else
        log_warn "Hyprctl not found, skipping reload ⚠️"
    fi

    return 0
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

home_main() {
    log_step "Starting HOME SETUP ⏳"

    if ! delete_files; then
        log_error "DELETING FILES FAILED ❌"
        return 1
    fi

    if ! create_files; then
        log_error "CREATING FILES FAILED ❌"
        return 1
    fi

    if ! link_files; then
        log_error "LINKING FILES FAILED ❌"
        return 1
    fi

    log_success "HOME SETUP COMPLETE 🎉"
    
    return 0
}