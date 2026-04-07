#!/bin/bash

CONF_DIR="${HOME}/arch/scripts/conf"
source "${CONF_DIR}/packages.conf"

# https://github.com/Jguer/yay
install_yay() {
    echo_color BLUE "Checking for existing Yay installation..."
    if command -v yay &> /dev/null; then
        echo_color GREEN "Yay is already installed."
        return 0
    fi

    cd ${HOME} || { echo_color RED "Error: Could not find home directory."; return 1; }
    echo_color BLUE "Installing git and base-devel..."
    sudo pacman -S --noconfirm --needed git base-devel || { echo_color RED "Error: Failed to install git and base-devel."; return 1; }
    
    if [ -d "yay" ]; then
        echo_color BLUE "Pulling latest Yay changes..."
        (cd yay && git pull) || { echo_color RED "Error: Failed to pull latest Yay changes."; return 1; }
    else
        echo_color BLUE "Cloning Yay repository..."
        git clone https://aur.archlinux.org/yay.git || { echo_color RED "Error: Failed to clone Yay repository."; return 1; }
    fi

    echo_color BLUE "Installing Yay..."
    cd yay || { echo_color RED "Error: Could not find Yay directory."; return 1; }
    makepkg -si --noconfirm || { echo_color RED "Error: Failed to build and install Yay."; return 1; }

    echo_color BLUE "Cleaning up Yay build files..."
    cd ${HOME} || { echo_color RED "Error: Could not find home directory."; return 1; }
    sudo rm -r yay

    echo_color GREEN "Yay installed successfully."

    return 0
}

remove_packages() {
    echo_color BLUE "Checking REMOVE_PACKAGES array..."
    if [[ -z "${REMOVE_PACKAGES+x}" || ${#REMOVE_PACKAGES[@]} -eq 0 ]]; then
        echo_color RED "Error: REMOVE_PACKAGES array is not defined or is empty."
        return 1
    fi

    echo_color BLUE "Removing packages..."
    for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
        if pacman -Q | awk '{print $1}' | grep -xq "$PACKAGE"; then
            echo_color BLUE "Removing (pacman): $PACKAGE"
            sudo pacman -Rns --noconfirm "$PACKAGE" || { echo_color RED "Error: Failed to remove $PACKAGE."; return 1; }
        elif command -v yay &>/dev/null && yay -Q | awk '{print $1}' | grep -xq "$PACKAGE"; then
            echo_color BLUE "Removing (yay): $PACKAGE"
            yay -Rns --noconfirm "$PACKAGE" || { echo_color RED "Error: Failed to remove $PACKAGE."; return 1; }
        else
            echo_color GREEN "$PACKAGE not found."
        fi
    done

    return 0
}

install_packages() {
    install_yay || { echo_color RED "Error: Failed to install Yay."; return 1; }

    echo_color BLUE "Checking INSTALL_PACKAGES array..."
    if [[ -z "${INSTALL_PACKAGES+x}" || ${#INSTALL_PACKAGES[@]} -eq 0 ]]; then
        echo_color RED "Error: INSTALL_PACKAGES array is not defined or is empty."
        return 1
    fi

    echo_color BLUE "Updating installed pacman and yay packages..."
    sudo pacman -Syu --noconfirm || { echo_color RED "Error: Failed to update package database."; return 1; }
    yay -Syu --noconfirm || { echo_color RED "Error: Failed to update AUR packages."; return 1; }

    echo_color BLUE "Installing packages..."
    for PACKAGE in "${INSTALL_PACKAGES[@]}"; do
        if pacman -Si "$PACKAGE" &>/dev/null; then
            echo_color BLUE "Installing (pacman): $PACKAGE"
            sudo pacman -S --noconfirm --needed "$PACKAGE" || { echo_color RED "Error: Failed to install $PACKAGE."; return 1; }
        elif command -v yay &>/dev/null && yay -Si "$PACKAGE" &>/dev/null; then
            echo_color BLUE "Installing (yay): $PACKAGE"
            yay -S --noconfirm --needed "$PACKAGE" || { echo_color RED "Error: Failed to install $PACKAGE."; return 1; }
        else
            echo_color RED "Error: $PACKAGE not found."
        fi
    done

    return 0
}

get_repositories() {
    echo_color BLUE "Checking REPOSITORIES array..."
    if [[ -z "${REPOSITORIES+x}" || ${#REPOSITORIES[@]} -eq 0 ]]; then
        echo_color RED "Error: REPOSITORIES array is not defined or is empty."
        return 1
    fi
    
    cd ${HOME} || { echo_color RED "Error: Could not find home directory."; return 1; }

    echo_color BLUE "Getting repositories..."
    for REPOSITORY in "${REPOSITORIES[@]}"; do
        REPO=$(echo "${REPOSITORY}" | awk '{print $1}')
        DESTINATION=$(echo "${REPOSITORY}" | awk '{print $2}')

        if [ -z "${DESTINATION}" ]; then
            DESTINATION=$(basename "${REPO}")
        fi

        if [ -d "${DESTINATION}" ]; then
            echo_color BLUE "Pulling latest ${REPO} changes..."
            git -C ${DESTINATION} pull || echo_color RED "Error: Failed to pull latest ${REPO} changes."
        else
            echo_color BLUE "Cloning ${REPO} repository..."
            git clone https://github.com/${REPO} ${DESTINATION} || echo_color RED "Error: Failed to clone ${REPO} repository."
        fi
    done

    return 0
}

packages_main() {
    starting "PACKAGE INSTALLATION"

    if ! remove_packages; then
        failed "PACKAGE REMOVAL"
    fi

    if ! install_packages; then
        failed "PACKAGE INSTALLATION"
    fi

    if ! get_repositories; then
        failed "GETTING REPOSITORIES"
    fi

    # sudo systemctl enable NetworkManager --now

    complete "PACKAGE INSTALLATION"

    return 0
}
