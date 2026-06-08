#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

WALLPAPER_PATH="${SCRIPT_DIR}/.assets/aurora.png"
AVAILABLE_THEMES=("wallpaper" "lockscreen" "loginscreen")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🎨 CachyOS Theming Script

Usage: ./theming.sh [OPTION]

Options:
  --help        Show this help message
  --all         Apply all available theming
  --wallpaper   Set CachyOS wallpaper to aurora.png
  --lockscreen  Set CachyOS lockscreen to aurora.png
  --loginscreen Set CachyOS login screen (SDDM) to aurora.png

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
        plasma-apply-wallpaperimage "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper for KDE Plasma ❌"; return 1; }
        log_success "Successfully applied wallpaper for KDE Plasma ✅"
    elif command -v gsettings &> /dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper for GNOME ❌"; return 1; }
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_PATH}" || { log_error "Failed to apply dark wallpaper for GNOME ❌"; return 1; }
        log_success "Successfully applied wallpaper for GNOME ✅"
    elif command -v feh &> /dev/null; then
        feh --bg-fill "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper using feh ❌"; return 1; }
        log_success "Successfully applied wallpaper using feh ✅"
    elif command -v swww &> /dev/null; then
        swww img "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper using swww ❌"; return 1; }
        log_success "Successfully applied wallpaper using swww ✅"
    else
        log_error "No supported wallpaper setter found for the current desktop environment ❌"
        return 1
    fi

    return 0
}

# ─── Theme: Lockscreen ──────────────────────────────────────────────────────────

apply_lockscreen() {
    log_step "Setting CachyOS lockscreen 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    log_info "Applying lockscreen from ${WALLPAPER_PATH} ⏳"

    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for KDE Plasma 6 ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for KDE Plasma 6 ✅"
    elif command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for KDE Plasma 5 ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for KDE Plasma 5 ✅"
    elif command -v gsettings &> /dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        gsettings set org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for GNOME ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for GNOME ✅"
    else
        log_error "No supported lockscreen setter found for the current desktop environment ❌"
        return 1
    fi

    return 0
}

# ─── Theme: Login Screen ────────────────────────────────────────────────────────

apply_loginscreen() {
    log_step "Setting CachyOS login screen (SDDM) 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    if ! command -v sddm &> /dev/null && [[ ! -d /usr/share/sddm ]]; then
        log_error "SDDM does not appear to be installed or running ❌"
        return 1
    fi

    local target_dir="/usr/share/backgrounds"
    local target_wallpaper="${target_dir}/cachyos-custom-login.png"

    log_info "Copying wallpaper to ${target_dir} for SDDM access ⏳"
    sudo mkdir -p "${target_dir}" || { log_error "Failed to create ${target_dir} ❌"; return 1; }
    sudo cp "${WALLPAPER_PATH}" "${target_wallpaper}" || { log_error "Failed to copy wallpaper for SDDM ❌"; return 1; }
    sudo chmod 644 "${target_wallpaper}" || { log_error "Failed to set permissions for SDDM wallpaper ❌"; return 1; }

    # Detect current SDDM theme
    local sddm_theme=""
    
    # Check configurations, later files override earlier ones
    for conf_file in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
        if [[ -f "${conf_file}" ]]; then
            local extracted_theme
            extracted_theme=$(grep -E '^Current=' "${conf_file}" | tail -n1 | cut -d'=' -f2 || true)
            if [[ -n "${extracted_theme}" ]]; then
                sddm_theme="${extracted_theme}"
            fi
        fi
    done

    # Fallback to CachyOS default or breeze if none found
    if [[ -z "${sddm_theme}" ]]; then
        if [[ -d "/usr/share/sddm/themes/cachyos" ]]; then
            sddm_theme="cachyos"
        elif [[ -d "/usr/share/sddm/themes/breeze" ]]; then
            sddm_theme="breeze"
        else
            log_error "Could not determine SDDM theme ❌"
            return 1
        fi
    fi

    log_info "Applying login screen wallpaper to SDDM theme: ${sddm_theme} ⏳"

    local theme_dir="/usr/share/sddm/themes/${sddm_theme}"
    if [[ ! -d "${theme_dir}" ]]; then
        log_error "SDDM theme directory not found: ${theme_dir} ❌"
        return 1
    fi

    local theme_conf_user="${theme_dir}/theme.conf.user"
    echo -e "[General]\nbackground=${target_wallpaper}\ntype=image" | sudo tee "${theme_conf_user}" > /dev/null || { log_error "Failed to update SDDM theme config ❌"; return 1; }

    # Bulletproof fallback: Overwrite the theme's default background image directly
    # This ensures the wallpaper changes even if the theme ignores theme.conf.user overrides
    local default_bg
    default_bg=$(grep -E '^[bB]ackground=' "${theme_dir}/theme.conf" 2>/dev/null | tail -n1 | cut -d'=' -f2 | tr -d ' ' || true)
    
    if [[ -n "${default_bg}" ]]; then
        # Handle relative paths within the theme directory
        if [[ "${default_bg}" != /* ]]; then
            default_bg="${theme_dir}/${default_bg}"
        fi
        
        # If the file exists, overwrite it with our wallpaper
        if [[ -f "${default_bg}" ]]; then
            log_info "Overwriting default theme background at ${default_bg} as fallback ⏳"
            sudo cp "${WALLPAPER_PATH}" "${default_bg}" || true
            sudo chmod 644 "${default_bg}" || true
        fi
    fi

    log_success "Successfully applied login screen wallpaper for SDDM ✅"
    log_info "Note: You may need to logout or reboot to see the SDDM changes. ℹ️"
    return 0
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

run_themes() {
    local themes=("$@")

    if [[ -z "${themes+x}" || ${#themes[@]} -eq 0 ]]; then
        log_error "No themes specified to run ❌"
        return 1
    fi

    for theme in "${themes[@]}"; do
        local fn="apply_${theme}"
        if declare -f "${fn}" > /dev/null 2>&1; then
            "${fn}" || { log_error "Failed to apply theme: ${theme} ❌"; return 1; }
        else
            log_error "Unknown theme option: ${theme} ❌"
            return 1
        fi
    done

    log_success "Done applying themes! 🎉"
    return 0
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
        --lockscreen)
            run_themes "lockscreen"
            ;;
        --loginscreen)
            run_themes "loginscreen"
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
