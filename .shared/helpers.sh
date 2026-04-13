#!/usr/bin/env bash

# ─── Logging ────────────────────────────────────────────────────────────────────

log_info() {
    echo "ℹ️ $*"
}

log_ok() {
    echo "✅ $*"
}

log_warn() {
    echo "⚠️ $*"
}

log_error() {
    echo "❌ $*"
}

log_step() {
    echo "⏳ $*"
}

# ─── Dependencies ──────────────────────────────────────────────────────────────

ensure_dependencies() {
    local deps=("$@")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &> /dev/null; then
            missing+=("${dep}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing missing dependencies: ${missing[*]}"
        sudo pacman -S --noconfirm --needed "${missing[@]}"
    fi
}

# ─── Git ────────────────────────────────────────────────────────────────────────

clone_or_pull() {
    local repo_url="$1"
    local target_dir="$2"

    if [[ -d "${target_dir}/.git" ]]; then
        log_info "Updating existing clone: ${target_dir}"
        git -C "${target_dir}" pull --ff-only || {
            log_warn "Pull failed — removing and re-cloning"
            rm -rf "${target_dir}"
            git clone --depth=1 "${repo_url}" "${target_dir}"
        }
    else
        log_info "Cloning ${repo_url} → ${target_dir}"
        mkdir -p "$(dirname "${target_dir}")"
        rm -rf "${target_dir}"
        git clone --depth=1 "${repo_url}" "${target_dir}"
    fi
}
