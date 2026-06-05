#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

WALLPAPER_PATH="${SCRIPT_DIR}/.assets/aurora.png"
AVAILABLE_THEMES=("wallpaper")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🎨 CachyOS Theming Script

Usage: ./theming.sh [OPTION]

Options:
  --help       Show this help message
  --all        Apply all available theming
  --wallpaper  Set CachyOS wallpaper to aurora.png

Available themes: ${AVAILABLE_THEMES[*]}
EOF
}

# ─── Theme: Wallpaper ───────────────────────────────────────────────────────────

apply_wallpaper() {
    log_step "Setting CachyOS wallpaper 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    log_info "Applying wallpaper from ${WALLPAPER_PATH} ⏳"

    if command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage "${WALLPAPER_PATH}"
        log_success "Successfully applied wallpaper for KDE Plasma ✅"
    elif command -v gsettings &> /dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER_PATH}"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_PATH}"
        log_success "Successfully applied wallpaper for GNOME ✅"
    elif command -v feh &> /dev/null; then
        feh --bg-fill "${WALLPAPER_PATH}"
        log_success "Successfully applied wallpaper using feh ✅"
    elif command -v swww &> /dev/null; then
        swww img "${WALLPAPER_PATH}"
        log_success "Successfully applied wallpaper using swww ✅"
    else
        log_error "No supported wallpaper setter found for the current desktop environment ❌"
        return 1
    fi
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

run_themes() {
    local themes=("$@")

    for theme in "${themes[@]}"; do
        local fn="apply_${theme}"
        if declare -f "${fn}" > /dev/null 2>&1; then
            "${fn}"
        else
            log_error "Unknown theme option: ${theme} ❌"
            return 1
        fi
    done

    log_success "Done applying themes! 🎉"
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        return 0
    fi

    case "$1" in
        --all)
            run_themes "${AVAILABLE_THEMES[@]}"
            ;;
        --wallpaper)
            run_themes "wallpaper"
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
